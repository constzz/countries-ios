import CountriesDomain
import Testing
@testable import CountriesUI

/// Every action, sent to the view model with a test repository: the state it leaves, the requests
/// it makes and the effects it emits.
@Suite("CountryListViewModel")
@MainActor
struct CountryListViewModelTests {
  private let rows = Array(CountrySummary.samples.prefix(4))

  // MARK: Loading

  @Test("AC-1.4 the first load shows loading")
  func firstLoadShowsLoading() async {
    let repository = SuspendingCountriesRepository()
    let viewModel = CountryListViewModel(repository: repository)

    viewModel.send(.appeared)

    #expect(viewModel.state.content == .loading)
    let isRequested = await eventually { await repository.calls == [.init(term: "", forceRefresh: false)] }
    #expect(isRequested)
  }

  @Test("AC-1.1 appearing loads every country")
  func appearingLoadsEveryCountry() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)

    await viewModel.send(.appeared).value

    #expect(await repository.calls == [.init(term: "", forceRefresh: false)])
  }

  @Test("AC-1.1 a response shows the loaded rows")
  func responseShowsTheLoadedRows() async {
    let viewModel = CountryListViewModel(repository: MockCountriesRepository(result: .success(rows)))

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .loaded(rows))
  }

  @Test("AC-1.4 appearing again fetches nothing")
  func appearingAgainFetchesNothing() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value
    let loaded = viewModel.state

    await viewModel.send(.appeared).value

    #expect(viewModel.state == loaded)
    #expect(await repository.calls.count == 1)
  }

  // MARK: Searching

  @Test("AC-1.4 a search keeps rows visible while searching")
  func searchKeepsRowsVisible() async {
    let repository = SuspendingCountriesRepository()
    let viewModel = await loadedViewModel(repository)

    viewModel.send(.searchSettled("ger"))

    #expect(viewModel.state.content == .loaded(rows))
    #expect(viewModel.state.isSearching)
    #expect(viewModel.state.query == "ger")
    let isRequested = await eventually { await repository.calls.last == .init(term: "ger", forceRefresh: false) }
    #expect(isRequested)
  }

  @Test("AC-1.4 a search with nothing on screen shows loading")
  func searchWithNothingOnScreenShowsLoading() async {
    let repository = MockCountriesRepository(result: .failure(.network))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    let search = viewModel.send(.searchSettled("ger"))

    #expect(viewModel.state.content == .loading)
    #expect(!viewModel.state.isSearching)
    await search.value
  }

  @Test("AC-1.5 no match shows the empty state with the query")
  func noMatchShowsTheEmptyState() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    await repository.setResult(.success([]))
    await viewModel.send(.searchSettled("zzz")).value

    #expect(viewModel.state.content == .empty(query: "zzz"))
    #expect(!viewModel.state.isSearching)
  }

  @Test("AC-1.2 typing updates the search text and feeds the search pipe")
  func typingFeedsTheSearchPipe() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository, debounceInterval: .milliseconds(20))
    await viewModel.send(.appeared).value

    viewModel.send(.searchTextChanged("Ger"))

    #expect(viewModel.state.searchText == "Ger")
    #expect(await repository.calls.count == 1)
    let isSearched = await eventually { await repository.calls.last == .init(term: "Ger", forceRefresh: false) }
    #expect(isSearched)
  }

  // MARK: Refreshing

  @Test("AC-1.4 a refresh keeps rows visible")
  func refreshKeepsRowsVisible() async {
    let viewModel = await loadedViewModel(SuspendingCountriesRepository())

    viewModel.send(.refreshRequested)

    #expect(viewModel.state.content == .loaded(rows))
    #expect(!viewModel.state.isSearching)
  }

  @Test("AC-1.8 refresh fetches the current query from the network")
  func refreshFetchesFromTheNetwork() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value
    await viewModel.send(.searchSettled("a")).value

    await repository.setResult(.success([rows[0]]))
    await viewModel.send(.refreshRequested).value

    #expect(viewModel.state.content == .loaded([rows[0]]))
    #expect(await repository.calls.last == .init(term: "a", forceRefresh: true))
  }

  @Test("AC-1.7 rows keep their codes across refresh and filtering")
  func rowsKeepTheirCodes() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    await viewModel.send(.refreshRequested).value
    let refreshed = ids(viewModel.state)
    await repository.setResult(.success([rows[1], rows[2]]))
    await viewModel.send(.searchSettled("an")).value

    #expect(refreshed == rows.map(\.code))
    #expect(ids(viewModel.state) == [rows[1].code, rows[2].code])
  }

  // MARK: Failing

  @Test("AC-1.6 a failure shows the error")
  func failureShowsTheError() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    await repository.setResult(.failure(.offline))
    await viewModel.send(.searchSettled("ger")).value

    #expect(viewModel.state.content == .failed(.offline))
    #expect(!viewModel.state.isSearching)
  }

  @Test("AC-1.6 retry repeats the last request")
  func retryRepeatsTheLastRequest() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value
    await repository.setResult(.failure(.network))
    await viewModel.send(.refreshRequested).value

    await repository.setResult(.success(rows))
    let retry = viewModel.send(.retryTapped)

    #expect(viewModel.state.content == .loading)
    await retry.value
    #expect(await repository.calls.last == .init(term: "", forceRefresh: true))
    #expect(viewModel.state.content == .loaded(rows))
  }

  // MARK: Ordering

  @Test("AC-1.11 a new fetch cancels the one in flight, and the cancelled one shows no error")
  func newFetchCancelsTheOneInFlight() async {
    let repository = SuspendingCountriesRepository()
    let viewModel = CountryListViewModel(repository: repository)

    let first = viewModel.send(.searchSettled("a"))
    let isRequested = await eventually { await repository.requestedTerms == ["a"] }
    #expect(isRequested)
    let second = viewModel.send(.searchSettled("ab"))
    await first.value

    #expect(await repository.cancelledTerms == ["a"])
    #expect(viewModel.state.content == .loading)

    let isSecondRequested = await eventually { await repository.requestedTerms == ["a", "ab"] }
    #expect(isSecondRequested)
    await repository.respond(to: "ab", with: rows)
    await second.value

    #expect(viewModel.state.content == .loaded(rows))
  }

  @Test("AC-1.11 a stale response never replaces newer results")
  func staleResponseIsIgnored() async {
    let repository = SuspendingCountriesRepository(honorsCancellation: false)
    let viewModel = await loadedViewModel(repository)

    let first = viewModel.send(.searchSettled("a"))
    let isFirstRequested = await eventually { await repository.requestedTerms.last == "a" }
    #expect(isFirstRequested)
    let second = viewModel.send(.searchSettled("ab"))
    let isSecondRequested = await eventually { await repository.requestedTerms.last == "ab" }
    #expect(isSecondRequested)
    await repository.respond(to: "ab", with: [rows[0]])
    await second.value
    let answered = viewModel.state

    await repository.respond(to: "a", with: rows)
    await first.value

    #expect(viewModel.state == answered)
    #expect(viewModel.state.content == .loaded([rows[0]]))
  }

  // MARK: Announcing

  @Test("AC-1.12 a search announces its result count")
  func searchAnnouncesItsResultCount() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    await viewModel.send(.searchSettled("a")).value
    await repository.setResult(.success([]))
    await viewModel.send(.searchSettled("zzz")).value

    #expect(await first(2, of: viewModel.effects()) == [.announce(resultCount: rows.count), .announce(resultCount: 0)])
  }

  @Test("AC-1.12 load and refresh announce nothing")
  func loadAndRefreshAnnounceNothing() async {
    let viewModel = CountryListViewModel(repository: MockCountriesRepository(result: .success(rows)))

    await viewModel.send(.appeared).value
    await viewModel.send(.refreshRequested).value
    await viewModel.send(.searchSettled("a")).value

    #expect(await first(1, of: viewModel.effects()) == [.announce(resultCount: rows.count)])
  }

  // MARK: Helpers

  /// A view model whose first load returned `rows` from `repository`.
  private func loadedViewModel(_ repository: SuspendingCountriesRepository) async -> CountryListViewModel {
    let viewModel = CountryListViewModel(repository: repository)
    let load = viewModel.send(.appeared)
    _ = await eventually { await repository.requestedTerms == [""] }
    await repository.respond(to: "", with: rows)
    await load.value
    return viewModel
  }

  private func ids(_ state: CountryListState) -> [String] {
    guard case let .loaded(rows) = state.content else {
      return []
    }
    return rows.map(\.id)
  }
}

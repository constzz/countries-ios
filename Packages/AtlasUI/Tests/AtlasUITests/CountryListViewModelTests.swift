import AtlasDomain
import AtlasMVITesting
import Testing
@testable import AtlasMVI
@testable import AtlasUI

/// Every action, sent to the view model with a test repository: the state it leaves and the
/// requests it makes.
@Suite("CountryListViewModel", .testTime)
@MainActor
struct CountryListViewModelTests {
  private let rows = Array(CountrySummary.samples.prefix(4))
  private var clock: TestClock {
    TestTime.clock
  }

  // MARK: Loading

  @Test("AC-1.4 the first load shows loading")
  func firstLoadShowsLoading() async {
    let (sut, repository) = makeSUT()

    sut.send(.appeared)

    #expect(sut.state.content == .loading)
    let isRequested = await eventually { await repository.calls == [.init(term: "", forceRefresh: false)] }
    #expect(isRequested)
  }

  @Test("AC-1.1 appearing loads every country")
  func appearingLoadsEveryCountry() async {
    let (sut, repository) = makeSUT(result: .success(rows))

    await sut.send(.appeared).value

    #expect(await repository.calls == [.init(term: "", forceRefresh: false)])
  }

  @Test("AC-1.1 a response shows the loaded rows")
  func responseShowsTheLoadedRows() async {
    let (sut, _) = makeSUT(result: .success(rows))

    await sut.send(.appeared).value

    #expect(sut.state.content == .loaded(rows))
  }

  @Test("AC-1.4 appearing again fetches nothing")
  func appearingAgainFetchesNothing() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value
    let loaded = sut.state

    await sut.send(.appeared).value

    #expect(sut.state == loaded)
    #expect(await repository.calls.count == 1)
  }

  // MARK: Searching

  @Test("AC-1.4 a search keeps rows visible and shows Searching after 0.5 s")
  func searchKeepsRowsVisible() async {
    let (sut, repository) = await makeSUT(loadedWith: rows)

    sut.receive(.searchSettled("ger"))

    #expect(sut.state.content == .loaded(rows))
    #expect(!sut.state.isSearching)
    #expect(sut.state.query == "ger")
    let isRequested = await eventually { await repository.calls.last == .init(term: "ger", forceRefresh: false) }
    #expect(isRequested)
    clock.advance(by: .milliseconds(499))
    #expect(!sut.state.isSearching)
    clock.advance(by: .milliseconds(1))
    let isShown = await eventually { sut.state.isSearching }
    #expect(isShown)
    #expect(sut.state.content == .loaded(rows))
  }

  @Test("AC-1.4 a quick search never shows Searching")
  func quickSearchNeverShowsSearching() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value
    await repository.setResult(.success([rows[0]]))

    let search = sut.receive(.searchSettled("ger"))
    #expect(!sut.state.isSearching)
    let isAnswered = await eventually { sut.state.content == .loaded([rows[0]]) }
    #expect(isAnswered)
    // Past the delay, then wait for the search's work: a wait the response failed to cancel
    // would have ended and shown Searching by now.
    clock.advance(by: .seconds(1))
    await search.value

    #expect(!sut.state.isSearching)
  }

  @Test("AC-1.4 Searching stays up when a newer search replaces a running one")
  func searchingStaysUpAcrossSearches() async {
    let (sut, _) = await makeSUT(loadedWith: rows)
    sut.receive(.searchSettled("a"))
    clock.advance(by: .milliseconds(500))
    let isShown = await eventually { sut.state.isSearching }
    #expect(isShown)

    sut.receive(.searchSettled("ab"))

    #expect(sut.state.isSearching)
  }

  @Test("AC-1.4 a search with nothing on screen shows loading")
  func searchWithNothingOnScreenShowsLoading() async {
    let (sut, _) = makeSUT(result: .failure(.network))
    await sut.send(.appeared).value

    let search = sut.receive(.searchSettled("ger"))

    #expect(sut.state.content == .loading)
    #expect(!sut.state.isSearching)
    await search.value
  }

  @Test("AC-1.5 no match shows the empty state with the query")
  func noMatchShowsTheEmptyState() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value

    await repository.setResult(.success([]))
    await sut.receive(.searchSettled("zzz")).value

    #expect(sut.state.content == .empty(query: "zzz"))
    #expect(!sut.state.isSearching)
  }

  @Test("AC-1.2 typing updates the search text and feeds the search pipe")
  func typingFeedsTheSearchPipe() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    let scheduler = TestTime.scheduler
    await sut.send(.appeared).value

    sut.send(.searchTextChanged("Ger"))

    #expect(sut.state.searchText == "Ger")
    #expect(sut.state.query.isEmpty)
    scheduler.advance(by: .milliseconds(300))
    #expect(sut.state.query == "Ger")
    let isSearched = await eventually { await repository.calls.last == .init(term: "Ger", forceRefresh: false) }
    #expect(isSearched)
  }

  // MARK: Refreshing

  @Test("AC-1.4 a refresh keeps rows visible")
  func refreshKeepsRowsVisible() async {
    let (sut, _) = await makeSUT(loadedWith: rows)

    sut.send(.refreshRequested)

    #expect(sut.state.content == .loaded(rows))
    #expect(!sut.state.isSearching)
  }

  @Test("AC-1.8 refresh fetches the current query from the network")
  func refreshFetchesFromTheNetwork() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value
    await sut.receive(.searchSettled("a")).value

    await repository.setResult(.success([rows[0]]))
    await sut.send(.refreshRequested).value

    #expect(sut.state.content == .loaded([rows[0]]))
    #expect(await repository.calls.last == .init(term: "a", forceRefresh: true))
  }

  @Test("AC-1.7 rows keep their codes across refresh and filtering")
  func rowsKeepTheirCodes() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value

    await sut.send(.refreshRequested).value
    let refreshed = ids(sut.state)
    await repository.setResult(.success([rows[1], rows[2]]))
    await sut.receive(.searchSettled("an")).value

    #expect(refreshed == rows.map(\.code))
    #expect(ids(sut.state) == [rows[1].code, rows[2].code])
  }

  // MARK: Failing

  @Test("AC-1.6 a failure shows the error")
  func failureShowsTheError() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value

    await repository.setResult(.failure(.offline))
    await sut.receive(.searchSettled("ger")).value

    #expect(sut.state.content == .failed(.offline))
    #expect(!sut.state.isSearching)
  }

  @Test("AC-1.6 retry after a failed refresh refreshes again")
  func retryAfterAFailedRefreshRefreshesAgain() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value
    await repository.setResult(.failure(.network))
    await sut.send(.refreshRequested).value

    await repository.setResult(.success(rows))
    let retry = sut.send(.retryTapped)

    #expect(sut.state.content == .loading)
    await retry.value
    #expect(await repository.calls.last == .init(term: "", forceRefresh: true))
    #expect(sut.state.content == .loaded(rows))
  }

  @Test("AC-1.6 retry after a failed search runs the term again")
  func retryAfterAFailedSearchRunsTheTermAgain() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    await sut.send(.appeared).value
    await repository.setResult(.failure(.offline))
    await sut.receive(.searchSettled("ger")).value

    await repository.setResult(.success([rows[0]]))
    let retry = sut.send(.retryTapped)

    #expect(sut.state.content == .loading)
    await retry.value
    #expect(await repository.calls.last?.term == "ger")
    #expect(sut.state.content == .loaded([rows[0]]))
  }

  // MARK: Ordering

  @Test("AC-1.11 a new fetch cancels the one in flight, and the cancelled one shows no error")
  func newFetchCancelsTheOneInFlight() async {
    let (sut, repository) = makeSUT()

    let first = sut.receive(.searchSettled("a"))
    let isRequested = await eventually { await repository.requestedTerms == ["a"] }
    #expect(isRequested)
    let second = sut.receive(.searchSettled("ab"))
    await first.value

    #expect(await repository.cancelledTerms == ["a"])
    #expect(sut.state.content == .loading)

    let isSecondRequested = await eventually { await repository.requestedTerms == ["a", "ab"] }
    #expect(isSecondRequested)
    await repository.respond(to: "ab", with: rows)
    await second.value

    #expect(sut.state.content == .loaded(rows))
  }

  @Test("AC-1.11 a stale response never replaces newer results")
  func staleResponseIsIgnored() async {
    let (sut, repository) = await makeSUT(loadedWith: rows, honorsCancellation: false)

    let first = sut.receive(.searchSettled("a"))
    let isFirstRequested = await eventually { await repository.requestedTerms.last == "a" }
    #expect(isFirstRequested)
    let second = sut.receive(.searchSettled("ab"))
    let isSecondRequested = await eventually { await repository.requestedTerms.last == "ab" }
    #expect(isSecondRequested)
    await repository.respond(to: "ab", with: [rows[0]])
    await second.value
    let answered = sut.state

    await repository.respond(to: "a", with: rows)
    await first.value

    #expect(sut.state == answered)
    #expect(sut.state.content == .loaded([rows[0]]))
  }

  // MARK: Helpers

  /// A view model whose repository answers every request with `result`.
  private func makeSUT(
    result: Result<[CountrySummary], RequestError>
  ) -> (sut: CountryListViewModel, repository: MockCountriesRepository) {
    let repository = MockCountriesRepository(result: result)
    return (CountryListViewModel(getCountries: GetCountriesUseCase(repository: repository)), repository)
  }

  /// A view model whose repository holds each request until the test answers it.
  private func makeSUT(
    honorsCancellation: Bool = true
  ) -> (sut: CountryListViewModel, repository: SuspendingCountriesRepository) {
    let repository = SuspendingCountriesRepository(honorsCancellation: honorsCancellation)
    return (CountryListViewModel(getCountries: GetCountriesUseCase(repository: repository)), repository)
  }

  /// A view model whose first load returned `loaded`, over a repository that holds each request
  /// until the test answers it.
  private func makeSUT(
    loadedWith loaded: [CountrySummary],
    honorsCancellation: Bool = true
  ) async -> (sut: CountryListViewModel, repository: SuspendingCountriesRepository) {
    let (sut, repository) = makeSUT(honorsCancellation: honorsCancellation)
    let load = sut.send(.appeared)
    _ = await eventually { await repository.requestedTerms == [""] }
    await repository.respond(to: "", with: loaded)
    await load.value
    return (sut, repository)
  }

  private func ids(_ state: CountryListState) -> [String] {
    guard case let .loaded(rows) = state.content else {
      return []
    }
    return rows.map(\.id)
  }
}

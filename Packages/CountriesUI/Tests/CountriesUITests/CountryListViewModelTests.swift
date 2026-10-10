import CountriesDomain
import Testing
@testable import CountriesUI

/// The view model runs the reducer's effects: fetching, cancelling and announcing. What each
/// action does to the state is covered by `CountryListReducerTests`.
@Suite("CountryListViewModel effects")
@MainActor
struct CountryListViewModelTests {
  private let rows = Array(CountrySummary.samples.prefix(3))

  @Test("AC-1.1 appearing loads every country")
  func appearingLoadsEveryCountry() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .loaded(rows))
    #expect(await repository.calls == [.init(term: "", forceRefresh: false)])
  }

  @Test("AC-1.8 a refresh can be awaited and fetches from the network")
  func refreshIsAwaitedAndForced() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    await viewModel.send(.appeared).value

    await repository.setResult(.success([rows[0]]))
    await viewModel.send(.refreshRequested).value

    #expect(viewModel.state.content == .loaded([rows[0]]))
    #expect(await repository.calls.last == .init(term: "", forceRefresh: true))
  }

  @Test("AC-1.6 a failure shows the error")
  func failureShowsTheError() async {
    let viewModel = CountryListViewModel(repository: MockCountriesRepository(result: .failure(.offline)))

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .failed(.offline))
  }

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

  @Test("AC-1.12 a search announces its result count")
  func searchAnnouncesItsResultCount() async {
    var announcements: [String] = []
    let viewModel = CountryListViewModel(
      repository: MockCountriesRepository(result: .success(rows)),
      announce: { announcements.append($0) }
    )

    await viewModel.send(.appeared).value
    await viewModel.send(.searchSettled("a")).value

    #expect(announcements == [SearchAnnouncement.text(forResultCount: rows.count)])
  }
}

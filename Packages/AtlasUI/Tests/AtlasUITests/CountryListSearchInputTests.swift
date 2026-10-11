import Testing
@testable import AtlasUI

/// The search field's input pipe: trim, debounce 300 ms, drop duplicates. The debounce waits on a
/// test scheduler, so each test moves the clock itself. Every search starts a new `state.request`,
/// so the tests read it right away instead of waiting to see whether the repository is called.
@Suite("CountryListViewModel search input")
@MainActor
struct CountryListSearchInputTests {
  private let repository = MockCountriesRepository()
  private let scheduler = TestScheduler()

  @Test("AC-1.2 typing searches once, 300 ms after the last keystroke")
  func typingSearchesOnceAfterAPause() async {
    let viewModel = makeViewModel()

    viewModel.send(.searchTextChanged("g"))
    scheduler.advance(by: .milliseconds(200))
    viewModel.send(.searchTextChanged("ge"))
    scheduler.advance(by: .milliseconds(200))
    viewModel.send(.searchTextChanged("ger"))
    scheduler.advance(by: .milliseconds(299))

    #expect(viewModel.state.request == nil)

    scheduler.advance(by: .milliseconds(1))

    #expect(viewModel.state.request == CountriesRequest(id: 1, term: "ger", kind: .search))
    scheduler.advance(by: .seconds(1))
    #expect(viewModel.state.request?.id == 1)
    let isSearched = await eventually { await repository.calls == [.init(term: "ger", forceRefresh: false)] }
    #expect(isSearched)
  }

  @Test("AC-1.2 an unchanged term issues no search")
  func unchangedTermIssuesNoSearch() {
    let viewModel = makeViewModel()
    viewModel.send(.searchTextChanged("ger"))
    scheduler.advance(by: .milliseconds(300))
    let searched = viewModel.state.request

    viewModel.send(.searchTextChanged("ger "))
    scheduler.advance(by: .milliseconds(300))

    #expect(searched?.term == "ger")
    #expect(viewModel.state.request == searched)
  }

  @Test("AC-1.2 returning to the settled term issues no search")
  func returningToTheSettledTermIssuesNoSearch() async {
    let viewModel = makeViewModel()
    await viewModel.send(.appeared).value
    let loaded = viewModel.state.request

    viewModel.send(.searchTextChanged("a"))
    viewModel.send(.searchTextChanged(""))
    scheduler.advance(by: .milliseconds(300))

    #expect(loaded?.kind == .load)
    #expect(viewModel.state.request == loaded)
  }

  private func makeViewModel() -> CountryListViewModel {
    CountryListViewModel(repository: repository, scheduler: scheduler)
  }
}

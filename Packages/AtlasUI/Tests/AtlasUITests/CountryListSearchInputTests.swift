import Testing
@testable import AtlasUI

/// The search field's input pipe: trim, debounce 300 ms, drop duplicates. The debounce waits on a
/// test scheduler, so each test moves the clock itself. A keystroke that must not search is
/// followed by one that does, so a search it started would show in the calls before the last one.
@Suite("CountryListViewModel search input", .testTime)
@MainActor
struct CountryListSearchInputTests {
  private let repository = MockCountriesRepository()
  private var scheduler: TestScheduler {
    TestTime.scheduler
  }

  @Test("AC-1.2 typing searches once, 300 ms after the last keystroke")
  func typingSearchesOnceAfterAPause() async {
    let viewModel = makeViewModel()

    viewModel.send(.searchTextChanged("g"))
    scheduler.advance(by: .milliseconds(200))
    viewModel.send(.searchTextChanged("ge"))
    scheduler.advance(by: .milliseconds(200))
    viewModel.send(.searchTextChanged("ger"))
    scheduler.advance(by: .milliseconds(299))

    #expect(viewModel.state.query == "")

    scheduler.advance(by: .milliseconds(1))

    #expect(viewModel.state.query == "ger")
    scheduler.advance(by: .seconds(1))
    await expectCalls(for: ["ger"], thenSearch: "gera", in: viewModel)
  }

  @Test("AC-1.2 an unchanged term issues no search")
  func unchangedTermIssuesNoSearch() async {
    let viewModel = makeViewModel()
    viewModel.send(.searchTextChanged("ger"))
    scheduler.advance(by: .milliseconds(300))

    viewModel.send(.searchTextChanged("ger "))
    scheduler.advance(by: .milliseconds(300))

    await expectCalls(for: ["ger"], thenSearch: "gera", in: viewModel)
  }

  @Test("AC-1.2 returning to the settled term issues no search")
  func returningToTheSettledTermIssuesNoSearch() async {
    let viewModel = makeViewModel()
    await viewModel.send(.appeared).value

    viewModel.send(.searchTextChanged("a"))
    viewModel.send(.searchTextChanged(""))
    scheduler.advance(by: .milliseconds(300))

    await expectCalls(for: [""], thenSearch: "b", in: viewModel)
  }

  private func makeViewModel() -> CountryListViewModel {
    CountryListViewModel(repository: repository)
  }

  /// Searches `last`, then expects the repository to have been called for `terms` and then `last`.
  private func expectCalls(
    for terms: [String],
    thenSearch last: String,
    in viewModel: CountryListViewModel
  ) async {
    viewModel.send(.searchTextChanged(last))
    scheduler.advance(by: .milliseconds(300))

    let expected = (terms + [last]).map { MockCountriesRepository.Call(term: $0, forceRefresh: false) }
    let isCalled = await eventually { await repository.calls == expected }
    #expect(isCalled)
  }
}

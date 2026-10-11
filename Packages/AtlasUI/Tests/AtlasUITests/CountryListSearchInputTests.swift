import Testing
@testable import AtlasUI

/// The search field's input pipe: trim, debounce, drop duplicates. A short interval keeps the
/// tests fast; the 300 ms default is the same pipe.
@Suite("CountryListViewModel search input")
@MainActor
struct CountryListSearchInputTests {
  private let interval = 20

  @Test("AC-1.2 typing searches once after a pause")
  func typingSearchesOnceAfterAPause() async {
    let repository = MockCountriesRepository()
    let viewModel = CountryListViewModel(repository: repository, debounceInterval: .milliseconds(interval))

    viewModel.send(.searchTextChanged("g"))
    viewModel.send(.searchTextChanged("ge"))
    viewModel.send(.searchTextChanged("ger"))

    let searched = await eventually { await !repository.calls.isEmpty }
    #expect(searched)
    try? await Task.sleep(for: .milliseconds(5 * interval))
    #expect(await repository.calls == [.init(term: "ger", forceRefresh: false)])
  }

  @Test("AC-1.2 an unchanged term issues no search")
  func unchangedTermIssuesNoSearch() async {
    let repository = MockCountriesRepository()
    let viewModel = CountryListViewModel(repository: repository, debounceInterval: .milliseconds(interval))

    viewModel.send(.searchTextChanged("ger"))
    let searched = await eventually { await !repository.calls.isEmpty }
    #expect(searched)
    viewModel.send(.searchTextChanged("ger "))
    try? await Task.sleep(for: .milliseconds(5 * interval))

    #expect(await repository.calls.map(\.term) == ["ger"])
  }

  @Test("AC-1.2 returning to the settled term issues no search")
  func returningToTheSettledTermIssuesNoSearch() async {
    let repository = MockCountriesRepository()
    let viewModel = CountryListViewModel(repository: repository, debounceInterval: .milliseconds(interval))
    await viewModel.send(.appeared).value

    viewModel.send(.searchTextChanged("a"))
    viewModel.send(.searchTextChanged(""))
    try? await Task.sleep(for: .milliseconds(5 * interval))

    #expect(await repository.calls.map(\.term) == [""])
  }
}

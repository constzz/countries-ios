import AtlasDomain
import AtlasMVITesting
import Foundation
import Testing
@testable import AtlasUI

/// The test plan runs in US English, so the announcements are checked against English text.
@Suite("CountryListViewModel announcements", .testTime)
@MainActor
struct CountryListAnnouncementTests {
  private let rows = Array(CountrySummary.samples.prefix(4))

  @Test("AC-1.12 a search announces its result count")
  func searchAnnouncesItsResultCount() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    let effects = viewModel.effects()
    await viewModel.send(.appeared).value

    await viewModel.send(.searchSettled("a")).value
    await repository.setResult(.success([]))
    await viewModel.send(.searchSettled("zzz")).value

    #expect(await first(2, of: effects) == [
      .announce("4 countries found"),
      .announce(String(localized: .countryListSearchNoResults)),
    ])
  }

  @Test("AC-1.12 the announcement uses plural variants")
  func announcementUsesPluralVariants() async {
    let repository = MockCountriesRepository(result: .success(rows))
    let viewModel = CountryListViewModel(repository: repository)
    let effects = viewModel.effects()
    await viewModel.send(.appeared).value

    await repository.setResult(.success([rows[0]]))
    await viewModel.send(.searchSettled("a")).value
    await repository.setResult(.success(Array(rows.prefix(2))))
    await viewModel.send(.searchSettled("ab")).value

    #expect(await first(2, of: effects) == [.announce("1 country found"), .announce("2 countries found")])
  }

  @Test("AC-1.12 load and refresh announce nothing")
  func loadAndRefreshAnnounceNothing() async {
    let viewModel = CountryListViewModel(repository: MockCountriesRepository(result: .success(rows)))
    let effects = viewModel.effects()

    await viewModel.send(.appeared).value
    await viewModel.send(.refreshRequested).value
    await viewModel.send(.searchSettled("a")).value

    #expect(await first(1, of: effects) == [.announce("4 countries found")])
  }
}

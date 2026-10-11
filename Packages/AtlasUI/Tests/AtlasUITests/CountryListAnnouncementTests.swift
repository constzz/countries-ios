import AtlasDomain
import AtlasMVITesting
import Foundation
import Testing
@testable import AtlasMVI
@testable import AtlasUI

/// The test plan runs in US English, so the announcements are checked against English text.
@Suite("CountryListViewModel announcements", .testTime)
@MainActor
struct CountryListAnnouncementTests {
  private let rows = Array(CountrySummary.samples.prefix(4))

  @Test("AC-1.12 a search announces its result count")
  func searchAnnouncesItsResultCount() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    let effects = sut.effects()
    await sut.send(.appeared).value

    await sut.receive(.searchSettled("a")).value
    await repository.setResult(.success([]))
    await sut.receive(.searchSettled("zzz")).value

    #expect(await first(2, of: effects) == [
      .announce("4 countries found"),
      .announce(String(localized: .countryListSearchNoResults)),
    ])
  }

  @Test("AC-1.12 the announcement uses plural variants")
  func announcementUsesPluralVariants() async {
    let (sut, repository) = makeSUT(result: .success(rows))
    let effects = sut.effects()
    await sut.send(.appeared).value

    await repository.setResult(.success([rows[0]]))
    await sut.receive(.searchSettled("a")).value
    await repository.setResult(.success(Array(rows.prefix(2))))
    await sut.receive(.searchSettled("ab")).value

    #expect(await first(2, of: effects) == [.announce("1 country found"), .announce("2 countries found")])
  }

  @Test("AC-1.12 load and refresh announce nothing")
  func loadAndRefreshAnnounceNothing() async {
    let (sut, _) = makeSUT(result: .success(rows))
    let effects = sut.effects()

    await sut.send(.appeared).value
    await sut.send(.refreshRequested).value
    await sut.receive(.searchSettled("a")).value

    #expect(await first(1, of: effects) == [.announce("4 countries found")])
  }

  // MARK: Helpers

  private func makeSUT(
    result: Result<[CountrySummary], RequestError>
  ) -> (sut: CountryListViewModel, repository: MockCountriesRepository) {
    let repository = MockCountriesRepository(result: result)
    return (CountryListViewModel(repository: repository), repository)
  }
}

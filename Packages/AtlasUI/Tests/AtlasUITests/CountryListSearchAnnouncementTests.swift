import Foundation
import Testing
@testable import AtlasUI

/// The test plan runs in English, so the plural variants are checked against English text.
@Suite("Country list search announcement")
struct CountryListSearchAnnouncementTests {
  @Test("AC-1.12 the announcement text uses plural variants")
  func announcementUsesPluralVariants() {
    #expect(CountryListSearchAnnouncement.text(forResultCount: 1) == "1 country found")
    #expect(CountryListSearchAnnouncement.text(forResultCount: 2) == "2 countries found")
    #expect(CountryListSearchAnnouncement.text(forResultCount: 250) == "250 countries found")
  }

  @Test("AC-1.12 no results is announced")
  func noResultsIsAnnounced() {
    let expected = String(localized: .countryListSearchNoResults)
    #expect(CountryListSearchAnnouncement.text(forResultCount: 0) == expected)
  }
}

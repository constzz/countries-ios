import Foundation
import Testing
@testable import CountriesUI

/// The test plan runs in English, so the plural variants are checked against English text.
@Suite("Search announcement")
struct SearchAnnouncementTests {
  @Test("AC-1.12 the announcement text uses plural variants")
  func announcementUsesPluralVariants() {
    #expect(SearchAnnouncement.text(forResultCount: 1) == "1 country found")
    #expect(SearchAnnouncement.text(forResultCount: 2) == "2 countries found")
    #expect(SearchAnnouncement.text(forResultCount: 250) == "250 countries found")
  }

  @Test("AC-1.12 no results is announced")
  func noResultsIsAnnounced() {
    let expected = String(localized: "No countries found", bundle: .module)
    #expect(SearchAnnouncement.text(forResultCount: 0) == expected)
  }
}

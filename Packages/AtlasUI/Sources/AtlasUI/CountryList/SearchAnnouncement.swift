import Foundation

/// What VoiceOver says when a search finishes.
enum SearchAnnouncement {
  static func text(forResultCount count: Int) -> String {
    if count == 0 {
      String(localized: .countryListSearchNoResults)
    } else {
      String(localized: .countryListSearchResultCount(count))
    }
  }
}

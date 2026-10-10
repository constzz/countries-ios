import Foundation

/// What VoiceOver says when a search finishes.
enum SearchAnnouncement {
  static func text(forResultCount count: Int) -> String {
    if count == 0 {
      String(
        localized: "No countries found",
        bundle: .module,
        comment: "VoiceOver announcement after a search that matched no country."
      )
    } else {
      String(
        localized: "\(count) countries found",
        bundle: .module,
        comment: "VoiceOver announcement after a search: the number of countries that match. Varies by plural."
      )
    }
  }
}

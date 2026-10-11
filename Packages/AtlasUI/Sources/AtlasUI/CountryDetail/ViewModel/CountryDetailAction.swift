import AtlasMVI

enum CountryDetailAction: MVIAction {
  case appeared
  case disappeared
  case retryTapped
  /// The header's name scrolled under the navigation bar, or back out from under it.
  case headerScrolled(underBar: Bool)
}

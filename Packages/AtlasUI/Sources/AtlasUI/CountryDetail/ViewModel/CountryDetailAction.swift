import AtlasDomain
import AtlasMVI

enum CountryDetailAction: MVIAction {
  // MARK: Sent by the view

  case appeared
  case disappeared
  case retryTapped
  /// The header's name scrolled under the navigation bar, or back out from under it.
  case headerScrolled(underBar: Bool)

  // MARK: Sent by the view model

  case responseReceived(Result<CountryDetails, RequestError>)
}

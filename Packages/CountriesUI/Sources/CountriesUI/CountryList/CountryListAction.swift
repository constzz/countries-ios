import CountriesDomain

/// Everything that can happen on the country list, named after what happened.
enum CountryListAction: MVIAction {
  // MARK: Sent by the view

  case appeared
  case searchTextChanged(String)
  case refreshRequested
  case retryTapped

  // MARK: Sent by the view model

  /// The search pipe settled on a trimmed term.
  case searchSettled(String)
  case responseReceived(requestID: Int, Result<[CountrySummary], CountriesError>)
}

import AtlasDomain

enum CountryListAction: MVIAction {
  // MARK: Sent by the view

  case appeared
  case searchTextChanged(String)
  case refreshRequested
  case retryTapped

  // MARK: Sent by the view model

  /// The search pipe settled on a trimmed term.
  case searchSettled(String)
  /// A search is still running long enough after it started to show its progress.
  case searchProgressDue(requestID: Int)
  case responseReceived(requestID: Int, Result<[CountrySummary], RequestError>)
}

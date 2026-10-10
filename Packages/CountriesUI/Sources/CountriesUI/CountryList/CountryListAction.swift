import CountriesDomain

/// Everything that can happen on the country list, named after what happened.
enum CountryListAction: Equatable {
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

/// Work the reducer asks the view model to do.
enum CountryListEffect: Equatable {
  /// Feed the search pipe.
  case debounce(String)
  /// Fetch, cancelling the fetch in flight.
  case fetch(CountriesRequest)
  /// Tell VoiceOver how many countries a search found.
  case announce(resultCount: Int)
}

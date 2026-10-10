import CountriesDomain

/// Everything that can happen on the country detail, named after what happened.
enum CountryDetailAction: MVIAction {
  // MARK: Sent by the view

  case appeared
  case disappeared
  case retryTapped

  // MARK: Sent by the view model

  case responseReceived(requestID: Int, Result<CountryDetails, CountriesError>)
}

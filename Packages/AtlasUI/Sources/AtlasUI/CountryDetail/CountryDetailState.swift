import AtlasDomain

struct CountryDetailState: MVIState {
  enum Content: Equatable {
    case idle
    case loading
    case loaded(CountryDetails)
    case failed(CountriesError)
  }

  var content: Content = .idle
  /// The latest request's id. Only its response is applied.
  var requestID = 0
  var isHeaderUnderBar = false
}

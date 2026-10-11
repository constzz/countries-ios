import AtlasDomain

/// Everything the country detail shows, as one value.
struct CountryDetailState: MVIState {
  enum Content: Equatable {
    /// Nothing requested yet, or the request was cancelled when the detail disappeared.
    case idle
    case loading
    case loaded(CountryDetails)
    /// Not found is `.failed(.notFound)`.
    case failed(CountriesError)
  }

  var content: Content = .idle
  /// The latest request's id. Only its response is applied.
  var requestID = 0
  /// The header's name is under the navigation bar, so the bar shows the name instead.
  var showsTitle = false
}

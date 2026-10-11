import AtlasDomain

struct CountryDetailState: MVIState {
  enum Content: Equatable {
    case idle
    case loading
    case loaded(CountryDetails)
    case failed(RequestError)
  }

  var content: Content = .idle
  var isHeaderUnderBar = false
}

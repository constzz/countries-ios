import AtlasMVI

struct CountryDetailState: MVIState {
  enum Content: Equatable {
    case idle
    case loading
    case loaded(CountryDetailValues)
    case failed(ErrorCopy)
  }

  var content: Content = .idle
  var isHeaderUnderBar = false
}

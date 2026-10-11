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

  /// The country's name once the header's name is under the navigation bar.
  var title: String {
    if case let .loaded(values) = content, isHeaderUnderBar {
      values.name
    } else {
      ""
    }
  }

  var phase: LoadPhase? {
    switch content {
    case .idle, .loading:
      .loading
    case .loaded:
      nil
    case let .failed(copy):
      .failed(copy)
    }
  }
}

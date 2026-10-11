import AtlasDomain
import AtlasMVI

struct CountryListState: MVIState {
  enum Content: Equatable {
    case idle
    /// A request with nothing to keep on screen.
    case loading
    case loaded([CountrySummary])
    case empty(query: String)
    case failed(ErrorCopy)
  }

  var content: Content = .idle
  /// The search field's text, as typed.
  var searchText = ""
  /// The term the search pipe settled on: trimmed and debounced.
  var query = ""
  /// A search is running over the current content.
  var isSearching = false

  var rows: [CountrySummary] {
    if case let .loaded(rows) = content {
      rows
    } else {
      []
    }
  }

  var phase: LoadPhase? {
    switch content {
    case .idle, .loading:
      .loading
    case .loaded:
      nil
    case let .empty(query):
      .empty(query: query)
    case let .failed(copy):
      .failed(copy)
    }
  }
}

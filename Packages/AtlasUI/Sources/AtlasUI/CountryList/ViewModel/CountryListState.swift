import AtlasDomain

struct CountryListState: MVIState {
  enum Content: Equatable {
    case idle
    /// A request with nothing to keep on screen.
    case loading
    case loaded([CountrySummary])
    case empty(query: String)
    case failed(RequestError)
  }

  var content: Content = .idle
  /// The search field's text, as typed.
  var searchText = ""
  /// The term the search pipe settled on: trimmed and debounced.
  var query = ""
  /// A search is running over the current content.
  var isSearching = false
  /// The latest request. Only its response is applied.
  var request: CountriesRequest?
}

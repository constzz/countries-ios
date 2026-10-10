/// The only place the country list's state changes. Pure: same state and action, same result.
enum CountryListReducer {
  static func reduce(
    _ state: CountryListState,
    _ action: CountryListAction
  ) -> (CountryListState, [CountryListEffect]) {
    var state = state
    switch action {
    case let .searchTextChanged(text):
      state.searchText = text
      return (state, [.debounce(text)])

    case let .searchSettled(term):
      let request = nextRequest(after: state, term: term, forceRefresh: false, kind: .search)
      state.request = request
      return (state, [.fetch(request)])

    case .appeared, .refreshRequested, .retryTapped, .responseReceived:
      return (state, [])
    }
  }

  private static func nextRequest(
    after state: CountryListState,
    term: String,
    forceRefresh: Bool,
    kind: CountriesRequest.Kind
  ) -> CountriesRequest {
    CountriesRequest(id: (state.request?.id ?? 0) + 1, term: term, forceRefresh: forceRefresh, kind: kind)
  }
}

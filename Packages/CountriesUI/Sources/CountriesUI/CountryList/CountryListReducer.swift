import CountriesDomain

/// The only place the country list's state changes. Pure: same state and action, same result.
enum CountryListReducer {
  static func reduce(
    _ state: CountryListState,
    _ action: CountryListAction
  ) -> (CountryListState, [CountryListEffect]) {
    var state = state
    switch action {
    case .appeared:
      guard state.content == .idle else {
        return (state, [])
      }
      return start(.load, term: state.query, forceRefresh: false, in: state)

    case let .searchTextChanged(text):
      state.searchText = text
      return (state, [.debounce(text)])

    case let .searchSettled(term):
      state.query = term
      return start(.search, term: term, forceRefresh: false, in: state)

    case .refreshRequested:
      return start(.refresh, term: state.query, forceRefresh: true, in: state)

    case .retryTapped:
      return retry(in: state)

    case let .responseReceived(requestID, result):
      return receive(result, for: requestID, in: state)
    }
  }

  /// Repeats the last request. Try Again sits on the error screen, so the retry replaces it with
  /// loading, even for a refresh.
  private static func retry(in state: CountryListState) -> (CountryListState, [CountryListEffect]) {
    let last = state.request ?? CountriesRequest(id: 0, term: state.query, forceRefresh: false, kind: .load)
    var (state, effects) = start(last.kind, term: last.term, forceRefresh: last.forceRefresh, in: state)
    if case .failed = state.content {
      state.content = .loading
    }
    return (state, effects)
  }

  /// Applies the response to the latest request; responses to older ones are ignored.
  private static func receive(
    _ result: Result<[CountrySummary], CountriesError>,
    for requestID: Int,
    in state: CountryListState
  ) -> (CountryListState, [CountryListEffect]) {
    guard let request = state.request, request.id == requestID else {
      return (state, [])
    }
    var state = state
    state.isSearching = false
    switch result {
    case let .success(countries):
      state.content = countries.isEmpty ? .empty(query: request.term) : .loaded(countries)
      return (state, request.kind == .search ? [.announce(resultCount: countries.count)] : [])
    case let .failure(error):
      state.content = .failed(error)
      return (state, [])
    }
  }

  /// Issues a request that replaces any in flight. Rows or an empty result stay on screen while
  /// it runs; with nothing to keep, the screen shows loading. A refresh shows the system's own
  /// refresh control, so it changes nothing here.
  private static func start(
    _ kind: CountriesRequest.Kind,
    term: String,
    forceRefresh: Bool,
    in state: CountryListState
  ) -> (CountryListState, [CountryListEffect]) {
    var state = state
    let request = CountriesRequest(id: (state.request?.id ?? 0) + 1, term: term, forceRefresh: forceRefresh, kind: kind)
    state.request = request
    switch (kind, state.content) {
    case (.refresh, _):
      state.isSearching = false
    case (_, .loaded), (_, .empty):
      state.isSearching = kind == .search
    case (_, .idle), (_, .loading), (_, .failed):
      state.content = .loading
      state.isSearching = false
    }
    return (state, [.fetch(request)])
  }
}

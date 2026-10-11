import AtlasDomain
import AtlasMVI
import Combine
import Foundation

final class CountryListViewModel: MVIViewModel<
  CountryListState,
  CountryListAction,
  CountryListEvent,
  CountryListEffect
> {
  private let repository: any CountriesRepository
  private lazy var searchInput: PassthroughSubject<String, Never> = makeSearchInput()
  private var fetchTask: Task<Void, Never>?
  private var searchProgressTask: Task<Void, Never>?

  init(repository: any CountriesRepository) {
    self.repository = repository
    super.init(initialState: CountryListState())
  }

  private func makeSearchInput() -> PassthroughSubject<String, Never> {
    let input = PassthroughSubject<String, Never>()
    let trimmed = input.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    subscribe(to: time.debounce(trimmed, for: .milliseconds(300)).removeDuplicates()) {
      .searchSettled($0)
    }
    return input
  }

  override func reduce(_ current: CountryListState, _ action: CountryListAction) -> CountryListState {
    switch action {
    case .appeared:
      handleAppeared(current)
    case let .searchTextChanged(text):
      handleSearchTextChanged(current, text)
    case .refreshRequested:
      handleRefreshRequested(current)
    case .retryTapped:
      handleRetryTapped(current)
    }
  }

  override func reduce(_ current: CountryListState, _ event: CountryListEvent) -> CountryListState {
    switch event {
    case let .searchSettled(term):
      handleSearchSettled(current, term)
    case .searchProgressDue:
      handleSearchProgressDue(current)
    case let .countriesLoaded(countries, request):
      handleCountriesLoaded(current, countries, request)
    case let .countriesFailedToLoad(error):
      handleCountriesFailedToLoad(current, error)
    }
  }

  // MARK: Handlers

  private func handleAppeared(_ current: CountryListState) -> CountryListState {
    guard current.content == .idle else {
      return current
    }
    return start(.load, term: current.query, in: current)
  }

  private func handleSearchTextChanged(_ current: CountryListState, _ text: String) -> CountryListState {
    var next = current
    next.searchText = text
    searchInput.send(text)
    return next
  }

  private func handleSearchSettled(_ current: CountryListState, _ term: String) -> CountryListState {
    // Typing "a" and deleting it within the debounce settles on the query already shown.
    guard term != current.query else {
      return current
    }
    var next = current
    next.query = term
    return start(.search, term: term, in: next)
  }

  private func handleSearchProgressDue(_ current: CountryListState) -> CountryListState {
    switch current.content {
    case .loaded, .empty:
      var next = current
      next.isSearching = true
      return next
    case .idle, .loading, .failed:
      return current
    }
  }

  private func handleRefreshRequested(_ current: CountryListState) -> CountryListState {
    start(.refresh, term: current.query, in: current)
  }

  private func handleRetryTapped(_ current: CountryListState) -> CountryListState {
    // The cache never holds a failure, so going to the network repeats a failed load or search too.
    var next = start(.refresh, term: current.query, in: current)
    if case .failed = next.content {
      next.content = .loading
    }
    return next
  }

  private func handleCountriesLoaded(
    _ current: CountryListState,
    _ countries: [CountrySummary],
    _ request: CountriesRequest
  ) -> CountryListState {
    searchProgressTask?.cancel()
    var next = current
    next.isSearching = false
    next.content = countries.isEmpty ? .empty(query: request.term) : .loaded(countries)
    if request.kind == .search {
      emit(.announce(Self.announcement(forResultCount: countries.count)))
    }
    return next
  }

  private func handleCountriesFailedToLoad(_ current: CountryListState, _ error: RequestError) -> CountryListState {
    searchProgressTask?.cancel()
    var next = current
    next.isSearching = false
    next.content = .failed(error == .offline ? .offline : .countryListFailure)
    return next
  }

  // MARK: Fetching

  private func start(
    _ kind: CountriesRequest.Kind,
    term: String,
    in current: CountryListState
  ) -> CountryListState {
    var next = current
    let request = CountriesRequest(term: term, kind: kind)
    searchProgressTask?.cancel()
    switch (kind, current.content) {
    case (.search, .loaded), (.search, .empty):
      if !current.isSearching {
        scheduleSearchProgress()
      }
    case (.refresh, _), (.load, .loaded), (.load, .empty):
      next.isSearching = false
    case (_, .idle), (_, .loading), (_, .failed):
      next.content = .loading
      next.isSearching = false
    }
    fetch(request)
    return next
  }

  private func scheduleSearchProgress() {
    let wait = time.wait(for: .milliseconds(500))
    searchProgressTask = launchEffect {
      try await wait()
    } then: { _ in
      .searchProgressDue
    }
  }

  private func fetch(_ request: CountriesRequest) {
    fetchTask?.cancel()
    fetchTask = launchEffect { [repository] in
      try await repository.countries(matching: request.term, forceRefresh: request.forceRefresh)
    } then: { result in
      switch result {
      case let .success(countries):
        .countriesLoaded(countries, request: request)
      case let .failure(error):
        .countriesFailedToLoad(error as? RequestError ?? .unknown)
      }
    }
  }

  // MARK: Text

  private static func announcement(forResultCount count: Int) -> String {
    if count == 0 {
      String(localized: .countryListSearchNoResults)
    } else {
      String(localized: .countryListSearchResultCount(count))
    }
  }
}

import AtlasDomain
import Combine
import Foundation

/// The country list's view model. Its handlers feed the search pipe, run one fetch at a time and
/// announce search results.
final class CountryListViewModel: MVIViewModel<CountryListState, CountryListAction, CountryListEffect> {
  private let repository: any CountriesRepository
  private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride
  private let searchProgressDelay: Duration
  /// Built on first use: SwiftUI builds a view's initial `@State` value every time it creates the
  /// view, so `init` only stores dependencies.
  private lazy var searchInput: PassthroughSubject<String, Never> = makeSearchInput()
  private var subscriptions: Set<AnyCancellable> = []
  private var fetchTask: Task<Void, Never>?
  private var searchProgressTask: Task<Void, Never>?

  init(
    repository: any CountriesRepository,
    debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
    searchProgressDelay: Duration = .milliseconds(500)
  ) {
    self.repository = repository
    self.debounceInterval = debounceInterval
    self.searchProgressDelay = searchProgressDelay
    super.init(initialState: CountryListState())
  }

  /// The search field's input pipe: trim, debounce, then drop repeats of the last term.
  private func makeSearchInput() -> PassthroughSubject<String, Never> {
    let input = PassthroughSubject<String, Never>()
    input
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] term in self?.send(.searchSettled(term)) }
      .store(in: &subscriptions)
    return input
  }

  override func reduce(_ current: CountryListState, _ action: CountryListAction) -> CountryListState {
    switch action {
    case .appeared:
      handleAppeared(current)
    case let .searchTextChanged(text):
      handleSearchTextChanged(current, text)
    case let .searchSettled(term):
      handleSearchSettled(current, term)
    case let .searchProgressDue(requestID):
      handleSearchProgressDue(current, requestID)
    case .refreshRequested:
      handleRefreshRequested(current)
    case .retryTapped:
      handleRetryTapped(current)
    case let .responseReceived(requestID, result):
      handleResponse(result, for: requestID, in: current)
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

  /// The pipe drops repeats of its own last term, not of the query already on screen: typing "a"
  /// and deleting it within the debounce settles on the blank term the list already shows.
  private func handleSearchSettled(_ current: CountryListState, _ term: String) -> CountryListState {
    guard term != current.query else {
      return current
    }
    var next = current
    next.query = term
    return start(.search, term: term, in: next)
  }

  /// Shows "Searching…" if the search is still the latest request and its content is on screen.
  private func handleSearchProgressDue(_ current: CountryListState, _ requestID: Int) -> CountryListState {
    guard let request = current.request, request.id == requestID, request.kind == .search else {
      return current
    }
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

  /// Repeats the last request. Try Again sits on the error screen, so the retry replaces it with
  /// loading, even for a refresh.
  private func handleRetryTapped(_ current: CountryListState) -> CountryListState {
    let last = current.request ?? CountriesRequest(id: 0, term: current.query, kind: .load)
    var next = start(last.kind, term: last.term, in: current)
    if case .failed = next.content {
      next.content = .loading
    }
    return next
  }

  /// Applies the response to the latest request; responses to older ones are ignored.
  private func handleResponse(
    _ result: Result<[CountrySummary], CountriesError>,
    for requestID: Int,
    in current: CountryListState
  ) -> CountryListState {
    guard let request = current.request, request.id == requestID else {
      return current
    }
    searchProgressTask?.cancel()
    var next = current
    next.isSearching = false
    switch result {
    case let .success(countries):
      next.content = countries.isEmpty ? .empty(query: request.term) : .loaded(countries)
      if request.kind == .search {
        emit(.announce(resultCount: countries.count))
      }
    case let .failure(error):
      next.content = .failed(error)
    }
    return next
  }

  // MARK: Fetching

  /// Issues a request that replaces any in flight. Rows or an empty result stay on screen while
  /// it runs, and a search over them shows "Searching…" once it has run a while, or keeps it up
  /// if it's already showing. With nothing to keep, the screen shows loading. A refresh shows the
  /// system's own refresh control, so it changes nothing here.
  private func start(
    _ kind: CountriesRequest.Kind,
    term: String,
    in current: CountryListState
  ) -> CountryListState {
    var next = current
    let request = CountriesRequest(
      id: (current.request?.id ?? 0) + 1,
      term: term,
      kind: kind
    )
    next.request = request
    searchProgressTask?.cancel()
    switch (kind, current.content) {
    case (.search, .loaded), (.search, .empty):
      if !current.isSearching {
        scheduleSearchProgress(for: request)
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

  /// Sends `.searchProgressDue` once `request` has run for `searchProgressDelay`, unless its
  /// response or a newer request cancels the wait first.
  private func scheduleSearchProgress(for request: CountriesRequest) {
    searchProgressTask = launchEffect { [weak self, searchProgressDelay] in
      do {
        try await Task.sleep(for: searchProgressDelay)
      } catch {
        return
      }
      self?.send(.searchProgressDue(requestID: request.id))
    }
  }

  /// Cancels the fetch in flight and starts `request`. A cancelled fetch sends nothing back.
  private func fetch(_ request: CountriesRequest) {
    fetchTask?.cancel()
    fetchTask = launchEffect { [weak self, repository] in
      let result: Result<[CountrySummary], CountriesError>
      do {
        result = try await .success(repository.countries(matching: request.term, forceRefresh: request.forceRefresh))
      } catch is CancellationError {
        return
      } catch {
        result = .failure(error as? CountriesError ?? .unknown)
      }
      await self?.send(.responseReceived(requestID: request.id, result)).value
    }
  }
}

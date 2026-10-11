import AtlasDomain
import Combine
import Foundation

final class CountryListViewModel: MVIViewModel<CountryListState, CountryListAction, CountryListEffect> {
  private let repository: any CountriesRepository
  private let debounced: (AnyPublisher<String, Never>) -> AnyPublisher<String, Never>
  private let makeSearchProgressWait: () -> @Sendable () async throws -> Void
  private lazy var searchInput: PassthroughSubject<String, Never> = makeSearchInput()
  private var subscriptions: Set<AnyCancellable> = []
  private var fetchTask: Task<Void, Never>?
  private var searchProgressTask: Task<Void, Never>?
  private var lastRequest: CountriesRequest?

  /// - Parameter scheduler: must run each action later, never inside `schedule`, or a term would
  ///   arrive in the middle of a `reduce`.
  init(
    repository: any CountriesRepository,
    scheduler: some Scheduler = DispatchQueue.main,
    clock: some Clock<Duration> = ContinuousClock()
  ) {
    self.repository = repository
    debounced = { $0.debounce(for: .milliseconds(300), scheduler: scheduler).eraseToAnyPublisher() }
    makeSearchProgressWait = {
      let deadline = clock.now.advanced(by: .milliseconds(500))
      return { try await clock.sleep(until: deadline, tolerance: nil) }
    }
    super.init(initialState: CountryListState())
  }

  private func makeSearchInput() -> PassthroughSubject<String, Never> {
    let input = PassthroughSubject<String, Never>()
    let trimmed = input.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    debounced(trimmed.eraseToAnyPublisher())
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
    case .searchProgressDue:
      handleSearchProgressDue(current)
    case .refreshRequested:
      handleRefreshRequested(current)
    case .retryTapped:
      handleRetryTapped(current)
    case let .responseReceived(request, result):
      handleResponse(current, request, result)
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
    let last = lastRequest ?? CountriesRequest(term: current.query, kind: .load)
    var next = start(last.kind, term: last.term, in: current)
    if case .failed = next.content {
      next.content = .loading
    }
    return next
  }

  private func handleResponse(
    _ current: CountryListState,
    _ request: CountriesRequest,
    _ result: Result<[CountrySummary], RequestError>
  ) -> CountryListState {
    searchProgressTask?.cancel()
    var next = current
    next.isSearching = false
    switch result {
    case let .success(countries):
      next.content = countries.isEmpty ? .empty(query: request.term) : .loaded(countries)
      if request.kind == .search {
        emit(.announce(Self.announcement(forResultCount: countries.count)))
      }
    case let .failure(error):
      next.content = .failed(error)
    }
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
    lastRequest = request
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
    let wait = makeSearchProgressWait()
    searchProgressTask = launchEffect { [weak self] in
      do {
        try await wait()
      } catch {
        return
      }
      guard !Task.isCancelled else {
        return
      }
      self?.send(.searchProgressDue)
    }
  }

  private func fetch(_ request: CountriesRequest) {
    fetchTask?.cancel()
    fetchTask = launchEffect { [weak self, repository] in
      let result: Result<[CountrySummary], RequestError>
      do {
        result = try await .success(repository.countries(matching: request.term, forceRefresh: request.forceRefresh))
      } catch is CancellationError {
        return
      } catch {
        result = .failure(error as? RequestError ?? .unknown)
      }
      guard !Task.isCancelled else {
        return
      }
      await self?.send(.responseReceived(request, result)).value
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

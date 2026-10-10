import CountriesDomain

/// The country detail's view model. It loads one country, by its code, from its own query, and
/// cancels the request when the detail disappears.
final class CountryDetailViewModel: MVIViewModel<CountryDetailState, CountryDetailAction, CountryDetailEffect> {
  private let code: String
  private let repository: any CountriesRepository
  private var fetchTask: Task<Void, Never>?

  /// Stores the dependencies and does nothing else: SwiftUI builds a view's initial `@State` value
  /// every time it creates the view.
  init(code: String, repository: any CountriesRepository) {
    self.code = code
    self.repository = repository
    super.init(initialState: CountryDetailState())
  }

  override func reduce(_ current: CountryDetailState, _ action: CountryDetailAction) -> CountryDetailState {
    switch action {
    case .appeared:
      handleAppeared(current)
    case .disappeared:
      handleDisappeared(current)
    case .retryTapped:
      handleRetryTapped(current)
    case .headerScrolled:
      current
    case let .responseReceived(requestID, result):
      handleResponse(result, for: requestID, in: current)
    }
  }

  // MARK: Handlers

  private func handleAppeared(_ current: CountryDetailState) -> CountryDetailState {
    guard current.content == .idle else {
      return current
    }
    return start(in: current)
  }

  /// A request still loading is cancelled, and the detail goes back to `.idle`, so it loads again
  /// if it reappears.
  private func handleDisappeared(_ current: CountryDetailState) -> CountryDetailState {
    guard current.content == .loading else {
      return current
    }
    fetchTask?.cancel()
    var next = current
    next.content = .idle
    return next
  }

  private func handleRetryTapped(_ current: CountryDetailState) -> CountryDetailState {
    guard case .failed = current.content else {
      return current
    }
    return start(in: current)
  }

  /// Applies the response to the latest request; responses to older ones are ignored.
  private func handleResponse(
    _ result: Result<CountryDetails, CountriesError>,
    for requestID: Int,
    in current: CountryDetailState
  ) -> CountryDetailState {
    guard requestID == current.requestID, current.content == .loading else {
      return current
    }
    var next = current
    switch result {
    case let .success(details):
      next.content = .loaded(details)
    case let .failure(error):
      next.content = .failed(error)
    }
    return next
  }

  // MARK: Fetching

  /// Shows loading and fetches the country, replacing any request in flight.
  private func start(in current: CountryDetailState) -> CountryDetailState {
    var next = current
    next.requestID += 1
    next.content = .loading
    fetch(requestID: next.requestID)
    return next
  }

  /// Cancels the fetch in flight and starts a new one. A cancelled fetch sends nothing back.
  private func fetch(requestID: Int) {
    fetchTask?.cancel()
    fetchTask = launchEffect { [weak self, repository, code] in
      let result: Result<CountryDetails, CountriesError>
      do {
        result = try await .success(repository.country(code: code))
      } catch is CancellationError {
        return
      } catch {
        result = .failure(error as? CountriesError ?? .unknown)
      }
      await self?.send(.responseReceived(requestID: requestID, result)).value
    }
  }
}

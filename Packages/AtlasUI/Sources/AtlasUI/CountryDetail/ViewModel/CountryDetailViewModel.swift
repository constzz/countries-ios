import AtlasDomain

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
    case let .headerScrolled(underBar):
      handleHeaderScrolled(current, underBar: underBar)
    case let .responseReceived(result):
      handleResponse(current, result)
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

  private func handleHeaderScrolled(_ current: CountryDetailState, underBar: Bool) -> CountryDetailState {
    var next = current
    next.isHeaderUnderBar = underBar
    return next
  }

  private func handleResponse(
    _ current: CountryDetailState,
    _ result: Result<CountryDetails, RequestError>
  ) -> CountryDetailState {
    guard current.content == .loading else {
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

  private func start(in current: CountryDetailState) -> CountryDetailState {
    var next = current
    next.content = .loading
    fetch()
    return next
  }

  /// Cancels the fetch in flight and starts a new one. A cancelled fetch sends nothing back, even
  /// if its response already arrived: the cancel and the check before sending both run on the main
  /// actor.
  private func fetch() {
    fetchTask?.cancel()
    fetchTask = launchEffect { [weak self, repository, code] in
      let result: Result<CountryDetails, RequestError>
      do {
        result = try await .success(repository.country(code: code))
      } catch is CancellationError {
        return
      } catch {
        result = .failure(error as? RequestError ?? .unknown)
      }
      guard !Task.isCancelled else {
        return
      }
      await self?.send(.responseReceived(result)).value
    }
  }
}

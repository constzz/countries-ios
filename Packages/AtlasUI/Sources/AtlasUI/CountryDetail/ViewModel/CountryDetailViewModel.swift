import AtlasDomain
import Foundation

final class CountryDetailViewModel: MVIViewModel<CountryDetailState, CountryDetailAction, CountryDetailEffect> {
  private let countryCode: String
  private let repository: any CountriesRepository
  private let locale: Locale
  private var fetchTask: Task<Void, Never>?

  /// Stores the dependencies and does nothing else: SwiftUI builds a view's initial `@State` value
  /// every time it creates the view.
  init(countryCode: String, repository: any CountriesRepository, locale: Locale = .autoupdatingCurrent) {
    self.countryCode = countryCode
    self.repository = repository
    self.locale = locale
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
      next.content = .loaded(values(for: details))
    case let .failure(error):
      next.content = .failed(Self.errorCopy(for: error))
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

  private func fetch() {
    fetchTask?.cancel()
    fetchTask = launchEffect { [repository, countryCode] in
      try await repository.country(code: countryCode)
    } then: { result in
      .responseReceived(result.mapError { $0 as? RequestError ?? .unknown })
    }
  }

  // MARK: Text

  private static func errorCopy(for error: RequestError) -> ErrorCopy {
    switch error {
    case .offline:
      .offline
    case .notFound:
      .countryNotFound
    case .network, .server, .decoding, .unknown:
      .countryDetailFailure
    }
  }

  /// A missing value reads "None", and lists use the locale's list format. Values from the API are
  /// shown as the API spells them.
  private func values(for details: CountryDetails) -> CountryDetailValues {
    var noneResource = LocalizedStringResource.countryDetailNone
    noneResource.locale = locale
    let none = String(localized: noneResource)
    func list(_ items: [String]) -> String {
      items.isEmpty ? none : items.formatted(.list(type: .and).locale(locale))
    }
    return CountryDetailValues(
      name: details.summary.name,
      flag: details.summary.emoji,
      capital: details.capital ?? none,
      currencies: list(details.currencies),
      languages: list(details.languages.map(\.name)),
      continent: details.summary.continent.name
    )
  }
}

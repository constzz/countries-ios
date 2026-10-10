import Combine
import CountriesDomain
import Foundation
import Observation

/// Loads and searches the country list.
@MainActor
@Observable
final class CountryListViewModel {
  private(set) var state: CountryListState = .idle
  /// A search is running while the current rows stay on screen.
  private(set) var isUpdating = false

  @ObservationIgnored private let repository: any CountriesRepository
  @ObservationIgnored private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

  init(
    repository: any CountriesRepository,
    debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
  ) {
    self.repository = repository
    self.debounceInterval = debounceInterval
  }

  // MARK: Events

  func searchTextChanged(_: String) {}
}

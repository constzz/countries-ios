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
  @ObservationIgnored private let searchInput = PassthroughSubject<String, Never>()
  @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []
  @ObservationIgnored private var requestTask: Task<Void, Never>?

  init(
    repository: any CountriesRepository,
    debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300)
  ) {
    self.repository = repository
    searchInput
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] term in self?.startSearch(term) }
      .store(in: &subscriptions)
  }

  // MARK: Events

  func searchTextChanged(_ text: String) {
    searchInput.send(text)
  }

  // MARK: Requests

  private func startSearch(_ term: String) {
    requestTask?.cancel()
    requestTask = Task { [repository] in
      _ = try? await repository.countries(matching: term, forceRefresh: false)
    }
  }
}

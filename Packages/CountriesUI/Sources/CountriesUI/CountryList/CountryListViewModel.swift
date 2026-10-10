import Combine
import CountriesDomain
import Foundation
import Observation

/// Holds the country list's state, feeds actions through the reducer and runs the effects it
/// returns.
@MainActor
@Observable
final class CountryListViewModel {
  private(set) var state = CountryListState()

  @ObservationIgnored private let repository: any CountriesRepository
  @ObservationIgnored private let announce: @MainActor (String) -> Void
  @ObservationIgnored private let searchInput = PassthroughSubject<String, Never>()
  @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []
  @ObservationIgnored private var fetchTask: Task<Void, Never>?

  init(
    repository: any CountriesRepository,
    debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
    announce: @escaping @MainActor (String) -> Void = { _ in }
  ) {
    self.repository = repository
    self.announce = announce
    searchInput
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
      .removeDuplicates()
      .sink { [weak self] term in self?.send(.searchSettled(term)) }
      .store(in: &subscriptions)
  }

  /// Applies `action` and starts its effects. The returned task finishes when they have, so
  /// `.refreshable` and tests can await it.
  @discardableResult
  func send(_ action: CountryListAction) -> Task<Void, Never> {
    let (newState, effects) = CountryListReducer.reduce(state, action)
    if newState != state {
      state = newState
    }
    let tasks = effects.compactMap(run)
    return Task {
      for task in tasks {
        await task.value
      }
    }
  }

  // MARK: Effects

  private func run(_ effect: CountryListEffect) -> Task<Void, Never>? {
    switch effect {
    case let .debounce(text):
      searchInput.send(text)
      return nil

    case let .fetch(request):
      fetchTask?.cancel()
      let task = Task { [weak self, repository] in
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
      fetchTask = task
      return task

    case .announce:
      return nil
    }
  }
}

import CountriesDomain

/// Holds every request until the test answers it, or until its task is cancelled.
actor SuspendingCountriesRepository: CountriesRepository {
  private(set) var calls: [MockCountriesRepository.Call] = []
  private(set) var cancelledTerms: [String] = []
  private var waiting: [String: CheckedContinuation<[CountrySummary], any Error>] = [:]
  private let honorsCancellation: Bool

  var requestedTerms: [String] {
    calls.map(\.term)
  }

  /// With `honorsCancellation` off, a cancelled request still waits for its answer, like a
  /// response already on its way.
  init(honorsCancellation: Bool = true) {
    self.honorsCancellation = honorsCancellation
  }

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    calls.append(MockCountriesRepository.Call(term: term, forceRefresh: forceRefresh))
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        if honorsCancellation, cancelledTerms.contains(term) {
          continuation.resume(throwing: CancellationError())
        } else {
          waiting[term] = continuation
        }
      }
    } onCancel: {
      Task { await self.cancel(term) }
    }
  }

  func respond(to term: String, with countries: [CountrySummary]) {
    waiting.removeValue(forKey: term)?.resume(returning: countries)
  }

  private func cancel(_ term: String) {
    cancelledTerms.append(term)
    if honorsCancellation {
      waiting.removeValue(forKey: term)?.resume(throwing: CancellationError())
    }
  }
}

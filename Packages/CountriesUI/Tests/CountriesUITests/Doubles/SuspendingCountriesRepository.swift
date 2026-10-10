import CountriesDomain

/// Holds every request until the test answers it, or until its task is cancelled.
actor SuspendingCountriesRepository: CountriesRepository {
  private(set) var requestedTerms: [String] = []
  private(set) var cancelledTerms: [String] = []
  private var waiting: [String: CheckedContinuation<[CountrySummary], any Error>] = [:]

  func countries(matching term: String, forceRefresh _: Bool) async throws -> [CountrySummary] {
    requestedTerms.append(term)
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        if cancelledTerms.contains(term) {
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
    waiting.removeValue(forKey: term)?.resume(throwing: CancellationError())
  }
}

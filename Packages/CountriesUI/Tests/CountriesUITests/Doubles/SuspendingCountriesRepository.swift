import CountriesDomain

/// Holds every request until the test answers it, or until its task is cancelled. Each request is
/// tracked on its own, so requests for the same term never clash.
actor SuspendingCountriesRepository: CountriesRepository {
  private struct Pending {
    let id: Int
    let term: String
    let continuation: CheckedContinuation<[CountrySummary], any Error>
  }

  private(set) var calls: [MockCountriesRepository.Call] = []
  /// The terms of the requests whose tasks were cancelled, in order.
  private(set) var cancelledTerms: [String] = []
  private var pending: [Pending] = []
  private var cancelledIDs: Set<Int> = []
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
    let id = calls.count
    calls.append(MockCountriesRepository.Call(term: term, forceRefresh: forceRefresh))
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        if honorsCancellation, cancelledIDs.contains(id) {
          continuation.resume(throwing: CancellationError())
        } else {
          pending.append(Pending(id: id, term: term, continuation: continuation))
        }
      }
    } onCancel: {
      Task { await self.cancel(id, term: term) }
    }
  }

  func country(code _: String) async throws -> CountryDetails {
    throw CountriesError.unknown
  }

  /// Answers the oldest request for `term` still waiting.
  func respond(to term: String, with countries: [CountrySummary]) {
    guard let index = pending.firstIndex(where: { $0.term == term }) else {
      return
    }
    pending.remove(at: index).continuation.resume(returning: countries)
  }

  private func cancel(_ id: Int, term: String) {
    cancelledIDs.insert(id)
    cancelledTerms.append(term)
    if honorsCancellation, let index = pending.firstIndex(where: { $0.id == id }) {
      pending.remove(at: index).continuation.resume(throwing: CancellationError())
    }
  }
}

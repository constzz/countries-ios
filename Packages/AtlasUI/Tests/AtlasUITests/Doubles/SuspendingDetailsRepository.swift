import AtlasDomain

/// Holds every `country(code:)` request until the test answers it by its index, or until its task
/// is cancelled. The list's requests fail at once.
actor SuspendingDetailsRepository: CountriesRepository {
  private struct Pending {
    let id: Int
    let continuation: CheckedContinuation<CountryDetails, any Error>
  }

  private(set) var requestedCodes: [String] = []
  private(set) var cancelledCount = 0
  private var pending: [Pending] = []
  private var cancelledIDs: Set<Int> = []
  private let honorsCancellation: Bool

  /// With `honorsCancellation` off, a cancelled request still waits for its answer, like a
  /// response already on its way.
  init(honorsCancellation: Bool = true) {
    self.honorsCancellation = honorsCancellation
  }

  func countries(matching _: String, forceRefresh _: Bool) async throws -> [CountrySummary] {
    throw CountriesError.unknown
  }

  func country(code: String) async throws -> CountryDetails {
    let id = requestedCodes.count
    requestedCodes.append(code)
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        if honorsCancellation, cancelledIDs.contains(id) {
          continuation.resume(throwing: CancellationError())
        } else {
          pending.append(Pending(id: id, continuation: continuation))
        }
      }
    } onCancel: {
      Task { await self.cancel(id) }
    }
  }

  /// Answers request `index`, counting from 0 in the order they came, if it's still waiting. A
  /// cancellation reaches the repository a moment late, so answering "the oldest request" could
  /// answer one already cancelled.
  func respond(to index: Int, with result: Result<CountryDetails, CountriesError>) {
    guard let position = pending.firstIndex(where: { $0.id == index }) else {
      return
    }
    pending.remove(at: position).continuation.resume(with: result.mapError { $0 as any Error })
  }

  private func cancel(_ id: Int) {
    cancelledIDs.insert(id)
    cancelledCount += 1
    if honorsCancellation, let index = pending.firstIndex(where: { $0.id == id }) {
      pending.remove(at: index).continuation.resume(throwing: CancellationError())
    }
  }
}

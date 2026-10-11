import os

/// A clock whose time moves only when `advance(by:)` moves it. A sleep ends once the clock reaches
/// its deadline, and throws `CancellationError` if its task is cancelled first.
final class TestClock: Clock {
  struct Instant: InstantProtocol {
    fileprivate let offset: Duration

    func advanced(by duration: Duration) -> Self {
      Self(offset: offset + duration)
    }

    func duration(to other: Self) -> Duration {
      other.offset - offset
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
      lhs.offset < rhs.offset
    }
  }

  private struct Sleeper {
    let deadline: Instant
    let continuation: CheckedContinuation<Void, any Error>
  }

  private struct State {
    var now = Instant(offset: .zero)
    var sleepers: [Int: Sleeper] = [:]
    /// Sleeps cancelled before they started waiting.
    var cancelled: Set<Int> = []
    var lastID = 0
  }

  private let state = OSAllocatedUnfairLock(initialState: State())

  var now: Instant {
    state.withLock { $0.now }
  }

  var minimumResolution: Duration {
    .zero
  }

  func sleep(until deadline: Instant, tolerance _: Duration? = nil) async throws {
    let id = state.withLock { state in
      state.lastID += 1
      return state.lastID
    }
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        let early: Result<Void, any Error>? = state.withLock { state in
          if state.cancelled.remove(id) != nil {
            return .failure(CancellationError())
          }
          if deadline <= state.now {
            return .success(())
          }
          state.sleepers[id] = Sleeper(deadline: deadline, continuation: continuation)
          return nil
        }
        if let early {
          continuation.resume(with: early)
        }
      }
    } onCancel: {
      let sleeper = state.withLock { state in
        let sleeper = state.sleepers.removeValue(forKey: id)
        if sleeper == nil {
          state.cancelled.insert(id)
        }
        return sleeper
      }
      sleeper?.continuation.resume(throwing: CancellationError())
    }
  }

  /// Moves the clock forward by `duration` and ends every sleep whose deadline it reaches.
  func advance(by duration: Duration) {
    let woken = state.withLock { state in
      state.now = state.now.advanced(by: duration)
      let now = state.now
      let due = state.sleepers.filter { $0.value.deadline <= now }
      for id in due.keys {
        state.sleepers.removeValue(forKey: id)
      }
      return Array(due.values)
    }
    for sleeper in woken {
      sleeper.continuation.resume()
    }
  }
}

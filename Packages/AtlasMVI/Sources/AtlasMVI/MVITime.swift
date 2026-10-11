import Combine
import Foundation

public struct MVITime: Sendable {
  @TaskLocal public static var current = MVITime(scheduler: DispatchQueue.main, clock: ContinuousClock())

  private let scheduler: any Scheduler & Sendable
  private let startWait: @Sendable (Duration) -> @Sendable () async throws -> Void

  /// - Parameter scheduler: must run each action later, never inside `schedule`, or a debounced
  ///   value would arrive in the middle of a `reduce`.
  public init(scheduler: some Scheduler & Sendable, clock: some Clock<Duration>) {
    self.scheduler = scheduler
    startWait = { duration in
      let deadline = clock.now.advanced(by: duration)
      return { try await clock.sleep(until: deadline, tolerance: nil) }
    }
  }

  public func debounce<Upstream: Publisher>(
    _ upstream: Upstream,
    for duration: Duration
  ) -> AnyPublisher<Upstream.Output, Upstream.Failure> {
    Self.debounce(upstream, for: duration, on: scheduler)
  }

  /// A wait that ends `duration` after this call, however late it starts.
  public func wait(for duration: Duration) -> @Sendable () async throws -> Void {
    startWait(duration)
  }

  private static func debounce<Upstream: Publisher>(
    _ upstream: Upstream,
    for duration: Duration,
    on scheduler: some Scheduler
  ) -> AnyPublisher<Upstream.Output, Upstream.Failure> {
    let (seconds, attoseconds) = duration.components
    let nanoseconds = Int(seconds) * 1_000_000_000 + Int(attoseconds / 1_000_000_000)
    return upstream.debounce(for: .nanoseconds(nanoseconds), scheduler: scheduler).eraseToAnyPublisher()
  }
}

import Combine
import Observation

/// The base of every screen's view model. Views use only `state`, `send(_:)` and `effects()`; the
/// view model's own work comes back as events, which only the base delivers.
@MainActor
@Observable
open class MVIViewModel<State: MVIState, Action: MVIAction, Event: MVIEvent, Effect: MVIEffect> {
  public private(set) var state: State
  public let time = MVITime.current

  /// The work launched by the `reduce` call in progress, so `send` can await it.
  @ObservationIgnored private var launchedWork: [Task<Void, Never>] = []
  @ObservationIgnored private var subscribers: [AsyncStream<Effect>.Continuation] = []
  @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

  public init(initialState: State) {
    state = initialState
  }

  /// Returns the state after `action`. With the other `reduce`, the only place the state changes:
  /// hand each case to a `handle…` method that reads `current`, never `state`, and return at once.
  open func reduce(_ current: State, _: Action) -> State {
    current
  }

  /// Returns the state after `event`, which `launchEffect(_:then:)` or `subscribe(to:then:)`
  /// produced.
  open func reduce(_ current: State, _: Event) -> State {
    current
  }

  /// Applies `action`. The returned task finishes when the work it launched has.
  @discardableResult
  public final func send(_ action: Action) -> Task<Void, Never> {
    apply { reduce($0, action) }
  }

  /// Applies `event`. Internal, so views can't deliver one; tests can, with `@testable import`.
  @discardableResult
  final func receive(_ event: Event) -> Task<Void, Never> {
    apply { reduce($0, event) }
  }

  /// Runs `work`, then delivers the event `then` makes from its result. A cancelled task delivers
  /// nothing, even if its result has already arrived: the cancel and the check before delivering
  /// both run on the main actor.
  @discardableResult
  public final func launchEffect<Value>(
    _ work: @escaping @MainActor () async throws -> Value,
    then event: @escaping @MainActor (Result<Value, any Error>) -> Event
  ) -> Task<Void, Never> {
    let task = Task { [weak self] in
      let result: Result<Value, any Error>
      do {
        result = try await .success(work())
      } catch is CancellationError {
        return
      } catch {
        result = .failure(error)
      }
      guard !Task.isCancelled else {
        return
      }
      await self?.receive(event(result)).value
    }
    launchedWork.append(task)
    return task
  }

  /// Delivers the event `then` makes from each value `publisher` sends, for as long as the view
  /// model lives. `publisher` must send on the main thread.
  public final func subscribe<Output>(
    to publisher: some Publisher<Output, Never>,
    then event: @escaping (Output) -> Event
  ) {
    publisher
      .sink { [weak self] value in self?.receive(event(value)) }
      .store(in: &subscriptions)
  }

  /// Sends a one-time UI event to every subscriber. With none, it's dropped: no screen is on
  /// display to handle it, and delivering it later would show a stale event.
  public final func emit(_ effect: Effect) {
    subscribers.removeAll { subscriber in
      if case .terminated = subscriber.yield(effect) {
        return true
      }
      return false
    }
  }

  /// The effects emitted from now on. Cancelling its iteration ends the stream.
  public final func effects() -> AsyncStream<Effect> {
    let (stream, continuation) = AsyncStream.makeStream(of: Effect.self)
    subscribers.append(continuation)
    return stream
  }

  private func apply(_ reduce: (State) -> State) -> Task<Void, Never> {
    let outerWork = launchedWork
    launchedWork = []
    let newState = reduce(state)
    let work = launchedWork
    launchedWork = outerWork
    if newState != state {
      state = newState
    }
    return Task {
      for task in work {
        await task.value
      }
    }
  }
}

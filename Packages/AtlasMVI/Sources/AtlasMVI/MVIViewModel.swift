import Observation

/// The base of every screen's view model. A subclass overrides `reduce(_:_:)`; views use only
/// `state`, `send(_:)` and `effects()`.
@MainActor
@Observable
open class MVIViewModel<State: MVIState, Action: MVIAction, Effect: MVIEffect> {
  public private(set) var state: State
  public let time = MVITime.current

  /// The work launched by the `reduce` call in progress, so `send` can await it.
  @ObservationIgnored private var launchedWork: [Task<Void, Never>] = []
  @ObservationIgnored private var subscribers: [AsyncStream<Effect>.Continuation] = []

  public init(initialState: State) {
    state = initialState
  }

  /// Returns the state after `action`. The only place the state changes: hand each action to a
  /// `handle…` method that reads `current`, never `state`, and return at once. Start async work
  /// with `launchEffect(_:then:)`, which sends its result back as an action.
  open func reduce(_ current: State, _: Action) -> State {
    current
  }

  /// Applies `action`. The returned task finishes when the work it launched has.
  @discardableResult
  public final func send(_ action: Action) -> Task<Void, Never> {
    let outerWork = launchedWork
    launchedWork = []
    let newState = reduce(state, action)
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

  /// Starts `work` on the main actor and returns its task, so the subclass can cancel it.
  @discardableResult
  public final func launchEffect(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
    let task = Task(operation: work)
    launchedWork.append(task)
    return task
  }

  /// Runs `work`, then sends the action `then` makes from its result. A cancelled task sends
  /// nothing, even if its result has already arrived: the cancel and the check before sending both
  /// run on the main actor.
  @discardableResult
  public final func launchEffect<Value>(
    _ work: @escaping @MainActor () async throws -> Value,
    then action: @escaping @MainActor (Result<Value, any Error>) -> Action
  ) -> Task<Void, Never> {
    launchEffect { [weak self] in
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
      await self?.send(action(result)).value
    }
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
}

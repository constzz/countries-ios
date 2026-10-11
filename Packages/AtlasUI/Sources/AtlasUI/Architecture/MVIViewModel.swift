import Observation

/// The base of every screen's view model. A subclass overrides `reduce(_:_:)`; views use only
/// `state`, `send(_:)` and `effects()`.
@MainActor
@Observable
class MVIViewModel<State: MVIState, Action: MVIAction, Effect: MVIEffect> {
  private(set) var state: State
  let time = MVITime.current

  /// The work launched by the `reduce` call in progress, so `send` can await it.
  @ObservationIgnored private var launchedWork: [Task<Void, Never>] = []
  @ObservationIgnored private var subscribers: [AsyncStream<Effect>.Continuation] = []

  init(initialState: State) {
    state = initialState
  }

  /// Returns the state after `action`. The only place the state changes: hand each action to a
  /// `handle…` method that reads `current`, never `state`, and return at once. Start async work
  /// with `launchEffect(_:)` and send its result back as an action.
  func reduce(_ current: State, _: Action) -> State {
    current
  }

  /// Applies `action`. The returned task finishes when the work it launched has.
  @discardableResult
  final func send(_ action: Action) -> Task<Void, Never> {
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
  final func launchEffect(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
    let task = Task(operation: work)
    launchedWork.append(task)
    return task
  }

  /// Sends a one-time UI event to every subscriber. With none, it's dropped: no screen is on
  /// display to handle it, and delivering it later would show a stale event.
  final func emit(_ effect: Effect) {
    subscribers.removeAll { subscriber in
      if case .terminated = subscriber.yield(effect) {
        return true
      }
      return false
    }
  }

  /// The effects emitted from now on. Cancelling its iteration ends the stream.
  func effects() -> AsyncStream<Effect> {
    let (stream, continuation) = AsyncStream.makeStream(of: Effect.self)
    subscribers.append(continuation)
    return stream
  }
}

import Observation

/// The base of every screen's view model. A subclass overrides `reduce(_:_:)`; views use only
/// `state`, `send(_:)` and `effects`.
@MainActor
@Observable
class MVIViewModel<State: MVIState, Action: MVIAction, Effect: MVIEffect> {
  private(set) var state: State

  init(initialState: State) {
    state = initialState
  }

  /// Returns the state after `action`. The only place the state changes: hand each action to a
  /// `handle…` method that reads `current`, never `state`, and return at once. Start async work
  /// with `launchEffect(_:)` and send its result back as an action.
  func reduce(_ current: State, _: Action) -> State {
    current
  }

  /// Applies `action`. The returned task finishes when the work it launched has, so
  /// `.refreshable` and tests can await it.
  @discardableResult
  final func send(_: Action) -> Task<Void, Never> {
    Task {}
  }

  /// Starts `work` on the main actor and returns its task, so the subclass can cancel it.
  @discardableResult
  final func launchEffect(_: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
    Task {}
  }

  /// Sends a one-time UI event to the view.
  final func emit(_: Effect) {}

  /// The effects the view handles, one stream per subscriber.
  var effects: AsyncStream<Effect> {
    AsyncStream { $0.finish() }
  }
}

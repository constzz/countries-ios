import Observation

/// The part of a view model a view may use. Views store their view model as this type, because
/// `reduce`, `launchEffect` and `emit` must be public for subclasses in other packages, and Swift has
/// no `protected`.
@MainActor
public protocol MVIViewModelProtocol<State, Action, Effect>: AnyObject, Observable {
  associatedtype State: MVIState
  associatedtype Action: MVIAction
  associatedtype Effect: MVIEffect

  var state: State { get }

  @discardableResult
  func send(_ action: Action) -> Task<Void, Never>

  func effects() -> AsyncStream<Effect>
}

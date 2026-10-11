import AtlasMVI

enum CounterAction: MVIAction {
  case incremented
  case nothingChanged
  case workStarted
  case longWorkStarted
  case longWorkCancelled
  case pingRequested(Int)
  /// Waits a second, then answers `value`, or fails when it's negative.
  case valueRequested(Int)
  case valueRequestCancelled
  /// Subscribes to `input`, whose values arrive as `.valueReceived`.
  case inputOpened
}

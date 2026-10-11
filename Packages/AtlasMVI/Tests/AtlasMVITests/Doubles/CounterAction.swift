import AtlasMVI

enum CounterAction: MVIAction {
  case incremented
  case nothingChanged
  case workStarted
  case workFinished
  case longWorkStarted
  case longWorkCancelled
  case longWorkStopped
  case pingRequested(Int)
  /// Waits a second, then answers `value`, or fails when it's negative.
  case valueRequested(Int)
  case valueRequestCancelled
  case valueReceived(Int)
  case valueFailed
}

import AtlasMVI

enum CounterEvent: MVIEvent {
  case workFinished
  case longWorkStopped
  case valueReceived(Int)
  case valueFailed
}

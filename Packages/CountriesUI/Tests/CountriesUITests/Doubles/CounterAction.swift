@testable import CountriesUI

enum CounterAction: MVIAction {
  case incremented
  case nothingChanged
  case workStarted
  case workFinished
  case longWorkStarted
  case longWorkCancelled
  case longWorkStopped
  case pingRequested(Int)
}

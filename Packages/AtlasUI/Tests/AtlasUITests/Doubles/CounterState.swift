@testable import AtlasUI

struct CounterState: MVIState {
  var count = 0
  var isWorkFinished = false
  var isWorkCancelled = false
}

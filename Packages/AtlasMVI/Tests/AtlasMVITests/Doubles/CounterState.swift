import AtlasMVI

struct CounterState: MVIState {
  var count = 0
  var isWorkFinished = false
  var isWorkCancelled = false
  var value: Int?
  var didFail = false
}

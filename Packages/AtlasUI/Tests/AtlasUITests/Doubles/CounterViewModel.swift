@testable import AtlasUI

/// The smallest view model on the shared base, for testing the base itself.
final class CounterViewModel: MVIViewModel<CounterState, CounterAction, CounterEffect> {
  private var longWork: Task<Void, Never>?

  init() {
    super.init(initialState: CounterState())
  }

  override func reduce(_ current: CounterState, _ action: CounterAction) -> CounterState {
    var next = current
    switch action {
    case .incremented:
      next.count += 1
    case .nothingChanged:
      break
    case .workStarted:
      launchEffect { [weak self] in
        await Task.yield()
        self?.send(.workFinished)
      }
    case .workFinished:
      next.isWorkFinished = true
    case .longWorkStarted:
      longWork = launchEffect { [weak self] in
        while !Task.isCancelled {
          try? await Task.sleep(for: .milliseconds(5))
        }
        self?.send(.longWorkStopped)
      }
    case .longWorkCancelled:
      longWork?.cancel()
    case .longWorkStopped:
      next.isWorkCancelled = true
    case let .pingRequested(value):
      emit(.pinged(value))
    }
    return next
  }
}

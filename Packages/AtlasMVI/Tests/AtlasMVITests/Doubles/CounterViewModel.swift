import AtlasMVI

/// The smallest view model on the shared base, for testing the base itself.
final class CounterViewModel: MVIViewModel<CounterState, CounterAction, CounterEffect> {
  private var longWork: Task<Void, Never>?
  private var valueRequest: Task<Void, Never>?

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
    case .valueRequested, .valueRequestCancelled, .valueReceived, .valueFailed:
      return handleValue(current, action)
    }
    return next
  }

  private func handleValue(_ current: CounterState, _ action: CounterAction) -> CounterState {
    var next = current
    switch action {
    case let .valueRequested(value):
      requestValue(value)
    case .valueRequestCancelled:
      valueRequest?.cancel()
    case let .valueReceived(value):
      next.value = value
    case .valueFailed:
      next.didFail = true
    default:
      break
    }
    return next
  }

  private func requestValue(_ value: Int) {
    let wait = time.wait(for: .seconds(1))
    valueRequest = launchEffect {
      try await wait()
      guard value >= 0 else {
        throw CounterError()
      }
      return value
    } then: { result in
      (try? result.get()).map(CounterAction.valueReceived) ?? .valueFailed
    }
  }
}

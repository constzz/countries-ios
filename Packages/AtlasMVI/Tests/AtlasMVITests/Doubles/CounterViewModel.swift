import AtlasMVI
import Combine

/// The smallest view model on the shared base, for testing the base itself.
final class CounterViewModel: MVIViewModel<CounterState, CounterAction, CounterEvent, CounterEffect> {
  let input = PassthroughSubject<Int, Never>()
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
      launchEffect {
        await Task.yield()
      } then: { _ in
        .workFinished
      }
    case .longWorkStarted:
      longWork = launchEffect {
        while !Task.isCancelled {
          try? await Task.sleep(for: .milliseconds(5))
        }
      } then: { _ in
        .longWorkStopped
      }
    case .longWorkCancelled:
      longWork?.cancel()
    case let .pingRequested(value):
      emit(.pinged(value))
    case let .valueRequested(value):
      requestValue(value)
    case .valueRequestCancelled:
      valueRequest?.cancel()
    case .inputOpened:
      subscribe(to: input) { .valueReceived($0) }
    }
    return next
  }

  override func reduce(_ current: CounterState, _ event: CounterEvent) -> CounterState {
    var next = current
    switch event {
    case .workFinished:
      next.isWorkFinished = true
    case .longWorkStopped:
      next.isLongWorkStopped = true
    case let .valueReceived(value):
      next.value = value
    case .valueFailed:
      next.didFail = true
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
      (try? result.get()).map(CounterEvent.valueReceived) ?? .valueFailed
    }
  }
}

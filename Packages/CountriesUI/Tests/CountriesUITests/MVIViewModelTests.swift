import Observation
import Testing
@testable import CountriesUI

/// The shared base every screen's view model subclasses, tested through a toy counter.
@Suite("MVIViewModel")
@MainActor
struct MVIViewModelTests {
  @Test("send applies reduce's new state")
  func sendAppliesTheNewState() {
    let viewModel = CounterViewModel()

    viewModel.send(.incremented)

    #expect(viewModel.state.count == 1)
  }

  @Test("an unchanged state doesn't notify observers")
  func unchangedStateDoesNotNotify() {
    let viewModel = CounterViewModel()
    let changes = ChangeCount()
    observeState(of: viewModel, counting: changes)

    viewModel.send(.nothingChanged)
    #expect(changes.value == 0)

    viewModel.send(.incremented)
    #expect(changes.value == 1)
  }

  @Test("send's task finishes after the work it launched")
  func sendTaskAwaitsLaunchedWork() async {
    let viewModel = CounterViewModel()

    let task = viewModel.send(.workStarted)
    #expect(!viewModel.state.isWorkFinished)
    await task.value

    #expect(viewModel.state.isWorkFinished)
  }

  @Test("a cancelled launched task stops")
  func cancelledWorkStops() async {
    let viewModel = CounterViewModel()

    let task = viewModel.send(.longWorkStarted)
    viewModel.send(.longWorkCancelled)
    await task.value

    #expect(viewModel.state.isWorkCancelled)
  }

  @Test("an emitted effect reaches the subscriber")
  func emittedEffectReachesSubscriber() async {
    let viewModel = CounterViewModel()
    let effects = viewModel.effects

    viewModel.send(.pingRequested(1))

    #expect(await first(1, of: effects) == [.pinged(1)])
  }

  @Test("an effect emitted before anyone subscribes reaches the first subscriber")
  func earlyEffectReachesFirstSubscriber() async {
    let viewModel = CounterViewModel()

    viewModel.send(.pingRequested(1))
    viewModel.send(.pingRequested(2))

    #expect(await first(2, of: viewModel.effects) == [.pinged(1), .pinged(2)])
  }

  @Test("a new subscriber after a cancelled one still gets effects")
  func newSubscriberAfterCancelledOne() async {
    let viewModel = CounterViewModel()
    let firstSubscriber = Task {
      for await _ in viewModel.effects {}
    }
    firstSubscriber.cancel()
    await firstSubscriber.value

    viewModel.send(.pingRequested(3))

    #expect(await first(1, of: viewModel.effects) == [.pinged(3)])
  }

  // MARK: Helpers

  /// Collects the first `count` effects, or fewer if the stream ends first.
  private func first(_ count: Int, of effects: AsyncStream<CounterEffect>) async -> [CounterEffect] {
    var received: [CounterEffect] = []
    for await effect in effects {
      received.append(effect)
      if received.count == count {
        break
      }
    }
    return received
  }

  /// Counts the next change to `state`. Observation reports only the first change after it starts.
  private func observeState(of viewModel: CounterViewModel, counting changes: ChangeCount) {
    withObservationTracking {
      _ = viewModel.state
    } onChange: {
      MainActor.assumeIsolated {
        changes.value += 1
      }
    }
  }
}

@MainActor
private final class ChangeCount {
  var value = 0
}

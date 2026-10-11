import AtlasMVITesting
import Observation
import Testing
@testable import AtlasMVI

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

  @Test("a cancelled launched task stops and delivers nothing")
  func cancelledWorkStops() async {
    let viewModel = CounterViewModel()

    let task = viewModel.send(.longWorkStarted)
    viewModel.send(.longWorkCancelled)
    await task.value

    #expect(!viewModel.state.isLongWorkStopped)
  }

  @Test("a subscribed publisher's values arrive as events")
  func subscribedValuesArriveAsEvents() {
    let viewModel = CounterViewModel()
    viewModel.send(.inputOpened)

    viewModel.input.send(5)

    #expect(viewModel.state.value == 5)
  }

  @Test("an event goes through the event reduce")
  func eventGoesThroughTheEventReduce() {
    let viewModel = CounterViewModel()

    viewModel.receive(.valueReceived(3))

    #expect(viewModel.state.value == 3)
  }

  @Test("an emitted effect reaches the subscriber")
  func emittedEffectReachesSubscriber() async {
    let viewModel = CounterViewModel()
    let effects = viewModel.effects()

    viewModel.send(.pingRequested(1))

    #expect(await first(1, of: effects) == [.pinged(1)])
  }

  @Test("an effect emitted while no one subscribes is dropped")
  func unheardEffectIsDropped() async {
    let viewModel = CounterViewModel()

    viewModel.send(.pingRequested(1))
    let effects = viewModel.effects()
    viewModel.send(.pingRequested(2))

    #expect(await first(1, of: effects) == [.pinged(2)])
  }

  @Test("a new subscriber after a cancelled one still gets effects")
  func newSubscriberAfterCancelledOne() async {
    let viewModel = CounterViewModel()
    let firstSubscriber = Task {
      for await _ in viewModel.effects() {}
    }
    firstSubscriber.cancel()
    await firstSubscriber.value

    let effects = viewModel.effects()
    viewModel.send(.pingRequested(3))

    #expect(await first(1, of: effects) == [.pinged(3)])
  }

  // MARK: Helpers

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

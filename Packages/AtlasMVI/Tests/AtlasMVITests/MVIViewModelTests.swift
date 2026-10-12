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
    let sut = makeSUT()

    sut.send(.incremented)

    #expect(sut.state.count == 1)
  }

  @Test("a view model works through MVIViewModelProtocol, as views hold it")
  func worksThroughTheProtocol() async {
    let sut: any MVIViewModelProtocol<CounterState, CounterAction, CounterEffect> = makeSUT()

    await sut.send(.incremented).value

    #expect(sut.state.count == 1)
  }

  @Test("an unchanged state doesn't notify observers")
  func unchangedStateDoesNotNotify() {
    let sut = makeSUT()
    let changes = ChangeCount()
    observeState(of: sut, counting: changes)

    sut.send(.nothingChanged)
    #expect(changes.value == 0)

    sut.send(.incremented)
    #expect(changes.value == 1)
  }

  @Test("send's task finishes after the work it launched")
  func sendTaskAwaitsLaunchedWork() async {
    let sut = makeSUT()

    let task = sut.send(.workStarted)
    #expect(!sut.state.isWorkFinished)
    await task.value

    #expect(sut.state.isWorkFinished)
  }

  @Test("a cancelled launched task stops and delivers nothing")
  func cancelledWorkStops() async {
    let sut = makeSUT()

    let task = sut.send(.longWorkStarted)
    sut.send(.longWorkCancelled)
    await task.value

    #expect(!sut.state.isLongWorkStopped)
  }

  @Test("a subscribed publisher's values arrive as events")
  func subscribedValuesArriveAsEvents() {
    let sut = makeSUT()
    sut.send(.inputOpened)

    sut.input.send(5)

    #expect(sut.state.value == 5)
  }

  @Test("an event goes through the event reduce")
  func eventGoesThroughTheEventReduce() {
    let sut = makeSUT()

    sut.receive(.valueReceived(3))

    #expect(sut.state.value == 3)
  }

  @Test("an emitted effect reaches the subscriber")
  func emittedEffectReachesSubscriber() async {
    let sut = makeSUT()
    let effects = sut.effects()

    sut.send(.pingRequested(1))

    #expect(await first(1, of: effects) == [.pinged(1)])
  }

  @Test("an effect emitted while no one subscribes is dropped")
  func unheardEffectIsDropped() async {
    let sut = makeSUT()

    sut.send(.pingRequested(1))
    let effects = sut.effects()
    sut.send(.pingRequested(2))

    #expect(await first(1, of: effects) == [.pinged(2)])
  }

  @Test("a new subscriber after a cancelled one still gets effects")
  func newSubscriberAfterCancelledOne() async {
    let sut = makeSUT()
    let firstSubscriber = Task {
      for await _ in sut.effects() {}
    }
    firstSubscriber.cancel()
    await firstSubscriber.value

    let effects = sut.effects()
    sut.send(.pingRequested(3))

    #expect(await first(1, of: effects) == [.pinged(3)])
  }

  // MARK: Helpers

  private func makeSUT() -> CounterViewModel {
    CounterViewModel()
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

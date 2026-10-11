import AtlasMVI
import AtlasMVITesting
import Testing

/// `launchEffect(_:then:)` on the toy counter, whose request waits a second on the test clock. Each
/// test moves the clock before the effect's task starts, so a wait's deadline must be set when the
/// wait is made.
@Suite("MVIViewModel launchEffect(_:then:)", .testTime)
@MainActor
struct LaunchEffectTests {
  @Test("the work's value comes back as an action")
  func valueComesBackAsAnAction() async {
    let sut = makeSUT()

    let request = sut.send(.valueRequested(7))
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(sut.state.value == 7)
  }

  @Test("the work's error comes back as an action")
  func errorComesBackAsAnAction() async {
    let sut = makeSUT()

    let request = sut.send(.valueRequested(-1))
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(sut.state.didFail)
    #expect(sut.state.value == nil)
  }

  @Test("a cancelled effect sends nothing")
  func cancelledEffectSendsNothing() async {
    let sut = makeSUT()

    let request = sut.send(.valueRequested(7))
    sut.send(.valueRequestCancelled)
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(sut.state.value == nil)
    #expect(!sut.state.didFail)
  }

  private func makeSUT() -> CounterViewModel {
    CounterViewModel()
  }
}

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
    let viewModel = CounterViewModel()

    let request = viewModel.send(.valueRequested(7))
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(viewModel.state.value == 7)
  }

  @Test("the work's error comes back as an action")
  func errorComesBackAsAnAction() async {
    let viewModel = CounterViewModel()

    let request = viewModel.send(.valueRequested(-1))
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(viewModel.state.didFail)
    #expect(viewModel.state.value == nil)
  }

  @Test("a cancelled effect sends nothing")
  func cancelledEffectSendsNothing() async {
    let viewModel = CounterViewModel()

    let request = viewModel.send(.valueRequested(7))
    viewModel.send(.valueRequestCancelled)
    TestTime.clock.advance(by: .seconds(1))
    await request.value

    #expect(viewModel.state.value == nil)
    #expect(!viewModel.state.didFail)
  }
}

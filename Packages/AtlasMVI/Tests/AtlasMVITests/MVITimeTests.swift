import AtlasMVI
import AtlasMVITesting
import Combine
import Testing

@Suite("MVITime", .testTime)
@MainActor
struct MVITimeTests {
  @Test("debounce emits the last value once the scheduler passes the interval")
  func debounceEmitsTheLastValue() {
    let sut = MVITime.current
    let input = PassthroughSubject<String, Never>()
    var received: [String] = []
    let subscription = sut.debounce(input, for: .milliseconds(300))
      .sink { received.append($0) }

    input.send("a")
    TestTime.scheduler.advance(by: .milliseconds(100))
    input.send("ab")
    TestTime.scheduler.advance(by: .milliseconds(299))
    #expect(received.isEmpty)

    TestTime.scheduler.advance(by: .milliseconds(1))

    #expect(received == ["ab"])
    subscription.cancel()
  }

  @Test(".testTime gives each view model the test's scheduler and clock")
  func timeReachesViewModels() async {
    let sut = CounterViewModel()
    let request = sut.send(.valueRequested(1))

    TestTime.clock.advance(by: .milliseconds(999))
    #expect(sut.state.value == nil)
    TestTime.clock.advance(by: .milliseconds(1))
    await request.value

    #expect(sut.state.value == 1)
  }
}

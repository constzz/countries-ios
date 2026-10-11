import Testing
@testable import AtlasUI

/// Gives each test its own `TestScheduler` and `TestClock` as the time of every view model it
/// creates. Time moves only when the test advances `TestTime.scheduler` or `TestTime.clock`.
struct TestTime: SuiteTrait, TestTrait, TestScoping {
  @TaskLocal private static var current: (scheduler: TestScheduler, clock: TestClock)?

  static var scheduler: TestScheduler {
    guard let current else {
      preconditionFailure("The suite needs the .testTime trait")
    }
    return current.scheduler
  }

  static var clock: TestClock {
    guard let current else {
      preconditionFailure("The suite needs the .testTime trait")
    }
    return current.clock
  }

  var isRecursive: Bool {
    true
  }

  func provideScope(
    for _: Test,
    testCase _: Test.Case?,
    performing function: @Sendable () async throws -> Void
  ) async throws {
    let scheduler = TestScheduler()
    let clock = TestClock()
    try await Self.$current.withValue((scheduler, clock)) {
      try await MVITime.$current.withValue(MVITime(scheduler: scheduler, clock: clock)) {
        try await function()
      }
    }
  }
}

extension Trait where Self == TestTime {
  static var testTime: Self {
    Self()
  }
}

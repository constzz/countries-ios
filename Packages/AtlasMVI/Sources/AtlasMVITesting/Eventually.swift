/// Polls `condition` until it holds, up to `attempts` times about 5 ms apart, and returns whether it
/// held. It runs on the caller's actor, so the condition can read main-actor state.
///
/// It counts attempts rather than watching a deadline: on a busy CI machine the main actor can
/// stall for seconds, and a deadline that passed during a stall would end the wait before the work
/// the test waits for had its turn.
public func eventually(
  isolation _: isolated (any Actor)? = #isolation,
  attempts: Int = 400,
  _ condition: () async -> Bool
) async -> Bool {
  for _ in 0 ..< attempts {
    if await condition() {
      return true
    }
    try? await Task.sleep(for: .milliseconds(5))
  }
  return await condition()
}

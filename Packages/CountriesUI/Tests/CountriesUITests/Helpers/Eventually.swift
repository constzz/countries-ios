/// Polls `condition` until it holds or `timeout` passes, and returns whether it held. It runs on
/// the caller's actor, so the condition can read main-actor state.
func eventually(
  isolation _: isolated (any Actor)? = #isolation,
  timeout: Duration = .seconds(2),
  _ condition: () async -> Bool
) async -> Bool {
  let deadline = ContinuousClock.now + timeout
  while ContinuousClock.now < deadline {
    if await condition() {
      return true
    }
    try? await Task.sleep(for: .milliseconds(5))
  }
  return await condition()
}

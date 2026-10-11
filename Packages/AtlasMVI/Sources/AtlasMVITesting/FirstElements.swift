/// The first `count` elements of `stream`, or fewer if it ends first. It runs on the caller's
/// actor, so main-actor tests can read a view model's effects.
public func first<Element>(
  isolation _: isolated (any Actor)? = #isolation,
  _ count: Int,
  of stream: AsyncStream<Element>
) async -> [Element] {
  var elements: [Element] = []
  for await element in stream {
    elements.append(element)
    if elements.count == count {
      break
    }
  }
  return elements
}

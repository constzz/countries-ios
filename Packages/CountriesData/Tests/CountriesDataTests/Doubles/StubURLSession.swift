import Apollo
import Foundation

/// Answers each request with the next of its response bodies, repeating the last, as an HTTP 200
/// JSON response. A real `ApolloClient` over it runs its whole request chain, cache included,
/// without the network.
actor StubURLSession: ApolloURLSession {
  /// How many requests reached the session.
  private(set) var requestCount = 0
  private var bodies: [Data]

  init(bodies: [Data]) {
    precondition(!bodies.isEmpty, "A stub session needs at least one body.")
    self.bodies = bodies
  }

  func chunks(for request: URLRequest) async throws -> (any AsyncChunkSequence, URLResponse) {
    requestCount += 1
    let body = bodies.count > 1 ? bodies.removeFirst() : bodies[0]
    guard
      let url = request.url,
      let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
      )
    else {
      throw URLError(.badURL)
    }
    return (SingleChunk(data: body), response)
  }
}

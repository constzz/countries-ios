import Apollo
import Foundation

/// A whole response body, which Apollo reads as one chunk.
struct SingleChunk: AsyncChunkSequence {
  let data: Data

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(data: data)
  }

  struct AsyncIterator: AsyncIteratorProtocol {
    var data: Data?

    mutating func next() async throws -> Data? {
      defer { data = nil }
      return data
    }
  }
}

import Apollo
import ApolloAPI
import Foundation
import Testing

/// Turns JSON text or a fixture file into the `JSONObject` Apollo builds selection sets from.
enum JSONFixture {
  static func object(_ json: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> JSONObject {
    try object(Data(json.utf8), sourceLocation: sourceLocation)
  }

  static func object(_ data: Data, sourceLocation: SourceLocation = #_sourceLocation) throws -> JSONObject {
    let value = try JSONSerialization.jsonObject(with: data)
    return try #require(value as? AnyHashable as? JSONObject, "Not a JSON object", sourceLocation: sourceLocation)
  }
}

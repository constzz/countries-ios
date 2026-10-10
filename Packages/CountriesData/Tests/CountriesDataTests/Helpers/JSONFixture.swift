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

extension JSONFixture {
  /// The `data` object of a response captured into `Fixtures/<name>.json`.
  static func responseData(_ name: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> JSONObject {
    let url = try #require(
      Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"),
      "No fixture \(name).json",
      sourceLocation: sourceLocation
    )
    let response = try object(Data(contentsOf: url), sourceLocation: sourceLocation)
    return try #require(response["data"] as? JSONObject, "\(name).json has no data", sourceLocation: sourceLocation)
  }
}

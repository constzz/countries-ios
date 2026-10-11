/// A language spoken in a country, as the API names it.
public struct Language: Hashable, Sendable {
  public let code: String
  public let name: String

  public init(code: String, name: String) {
    self.code = code
    self.name = name
  }
}

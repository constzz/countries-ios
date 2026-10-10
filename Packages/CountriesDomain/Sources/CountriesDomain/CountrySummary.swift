/// A continent as the API names it.
public struct Continent: Hashable, Sendable {
  public let code: String
  public let name: String

  public init(code: String, name: String) {
    self.code = code
    self.name = name
  }
}

/// What the country list shows for one country. The country code is its identity, so a row keeps
/// it across reloads and filtering.
public struct CountrySummary: Identifiable, Hashable, Sendable {
  public let code: String
  public let name: String
  public let emoji: String
  public let continent: Continent

  public var id: String {
    code
  }

  public init(code: String, name: String, emoji: String, continent: Continent) {
    self.code = code
    self.name = name
    self.emoji = emoji
    self.continent = continent
  }
}

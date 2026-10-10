/// What the detail screen shows for one country: the fields the list shows, plus its capital,
/// currencies and languages.
public struct CountryDetails: Identifiable, Hashable, Sendable {
  /// The fields the list shows: code, name, flag and continent.
  public let summary: CountrySummary
  /// `nil` when the country has none.
  public let capital: String?
  /// ISO 4217 codes, main currency first.
  public let currencies: [String]
  /// Main language first.
  public let languages: [Language]

  public var id: String {
    ""
  }

  public init(summary: CountrySummary, capital: String?, currencies: [String], languages: [Language]) {
    self.summary = summary
    self.capital = capital
    self.currencies = currencies
    self.languages = languages
  }
}

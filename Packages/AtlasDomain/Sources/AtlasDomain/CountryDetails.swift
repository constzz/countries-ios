public struct CountryDetails: Identifiable, Hashable, Sendable {
  public let summary: CountrySummary
  public let capital: String?
  /// ISO 4217 codes.
  public let currencies: [String]
  public let languages: [Language]

  public var id: String {
    summary.id
  }

  public init(summary: CountrySummary, capital: String?, currencies: [String], languages: [Language]) {
    self.summary = summary
    self.capital = capital
    self.currencies = currencies
    self.languages = languages
  }
}

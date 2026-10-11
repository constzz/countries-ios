public protocol CountriesRepository: Sendable {
  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary]
  func country(code: String) async throws -> CountryDetails
}

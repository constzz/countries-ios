/// The countries API. Every call reaches the network, and throws `RequestError`, or
/// `CancellationError` when cancelled.
protocol CountriesRemoteDataSource: Sendable {
  /// Every country for a blank term.
  func countries(matching term: String) async throws -> [CountriesAPI.CountryBasics]
  /// `nil` when no country has the code.
  func country(code: String) async throws -> CountriesAPI.CountryQuery.Data.Country?
}

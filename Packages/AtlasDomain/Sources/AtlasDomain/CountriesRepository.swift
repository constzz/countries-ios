/// The source of country data.
public protocol CountriesRepository: Sendable {
  /// Countries whose name matches `term`, sorted by name. A blank term returns every country.
  ///
  /// - Parameter forceRefresh: fetch from the network, bypassing any cached response.
  /// - Throws: `CountriesError`, or `CancellationError` when the task is cancelled.
  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary]

  /// The country with `code`, as the API spells it (upper case).
  ///
  /// - Throws: `CountriesError.notFound` when there's no such country, another `CountriesError`,
  ///   or `CancellationError` when the task is cancelled.
  func country(code: String) async throws -> CountryDetails
}

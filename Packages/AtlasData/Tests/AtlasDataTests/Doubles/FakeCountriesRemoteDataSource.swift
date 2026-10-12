import AtlasDomain
@testable import AtlasData

/// Answers each request with the next of its results, repeating the last, and records what was
/// asked.
actor FakeCountriesRemoteDataSource: CountriesRemoteDataSource {
  private(set) var requestedTerms: [String] = []
  private(set) var requestedCodes: [String] = []
  private var countriesResults: [Result<[CountriesAPI.CountryBasics], RequestError>]
  private var countryResults: [Result<CountriesAPI.CountryQuery.Data.Country?, RequestError>]

  init(
    countries: [Result<[CountriesAPI.CountryBasics], RequestError>],
    country: [Result<CountriesAPI.CountryQuery.Data.Country?, RequestError>]
  ) {
    precondition(!countries.isEmpty && !country.isEmpty, "A fake data source needs at least one result of each.")
    countriesResults = countries
    countryResults = country
  }

  func countries(matching term: String) async throws -> [CountriesAPI.CountryBasics] {
    requestedTerms.append(term)
    return try Self.next(from: &countriesResults).get()
  }

  func country(code: String) async throws -> CountriesAPI.CountryQuery.Data.Country? {
    requestedCodes.append(code)
    return try Self.next(from: &countryResults).get()
  }

  private static func next<Value>(from results: inout [Result<Value, RequestError>]) -> Result<Value, RequestError> {
    results.count > 1 ? results.removeFirst() : results[0]
  }
}

import AtlasDomain
import Foundation
import os

/// Keeps only successes, so a retry after a failure always reaches the network.
struct CountriesRepositoryImpl: CountriesRepository {
  private let remote: any CountriesRemoteDataSource
  private let summaries: InMemoryCache<String, [CountrySummary]>
  private let details: InMemoryCache<String, CountryDetails>

  init(
    remote: any CountriesRemoteDataSource,
    summaries: InMemoryCache<String, [CountrySummary]>,
    details: InMemoryCache<String, CountryDetails>
  ) {
    self.remote = remote
    self.summaries = summaries
    self.details = details
  }

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    let key = term.trimmingCharacters(in: .whitespacesAndNewlines)
    if !forceRefresh, let cached = await summaries.value(for: key) {
      return cached
    }
    let countries = try await remote.countries(matching: key).map(CountrySummaryMapper.map)
    await summaries.insert(countries, for: key)
    return countries
  }

  func country(code: String) async throws -> CountryDetails {
    if let cached = await details.value(for: code) {
      return cached
    }
    guard let country = try await remote.country(code: code) else {
      Logger.network.error("No country has the code \(code, privacy: .public)")
      throw RequestError.notFound
    }
    let mapped = CountryDetailsMapper.map(country)
    await details.insert(mapped, for: code)
    return mapped
  }
}

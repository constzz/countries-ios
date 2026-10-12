import AtlasDomain
import Foundation
import os

/// Keeps only successes, so a retry after a failure always reaches the network.
struct CountriesRepositoryImpl: CountriesRepository {
  private let remoteDataSource: any CountriesRemoteDataSource
  private let summariesCache: InMemoryCache<String, [CountrySummary]>
  private let detailsCache: InMemoryCache<String, CountryDetails>

  init(
    remoteDataSource: any CountriesRemoteDataSource,
    summariesCache: InMemoryCache<String, [CountrySummary]>,
    detailsCache: InMemoryCache<String, CountryDetails>
  ) {
    self.remoteDataSource = remoteDataSource
    self.summariesCache = summariesCache
    self.detailsCache = detailsCache
  }

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    let key = term.trimmingCharacters(in: .whitespacesAndNewlines)
    if !forceRefresh, let cached = await summariesCache.value(for: key) {
      return cached
    }
    let countries = try await remoteDataSource.countries(matching: key).map(CountrySummaryMapper.map)
    await summariesCache.insert(countries, for: key)
    return countries
  }

  func country(code: String) async throws -> CountryDetails {
    if let cached = await detailsCache.value(for: code) {
      return cached
    }
    guard let country = try await remoteDataSource.country(code: code) else {
      Logger.network.error("No country has the code \(code, privacy: .public)")
      throw RequestError.notFound
    }
    let mapped = CountryDetailsMapper.map(country)
    await detailsCache.insert(mapped, for: code)
    return mapped
  }
}

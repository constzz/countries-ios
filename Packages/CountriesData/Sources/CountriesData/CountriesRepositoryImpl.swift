import Apollo
import CountriesDomain
import Foundation
import os

/// Creates the repository the app uses, backed by the Countries GraphQL API at `endpoint`.
public func makeCountriesRepository(endpoint: URL) -> any CountriesRepository {
  CountriesRepositoryImpl(client: ApolloGraphQLClient(client: makeApolloClient(endpoint: endpoint)))
}

/// How long a request may wait for data before it fails, instead of URLSession's 60 s.
private let requestTimeout: TimeInterval = 15

func makeApolloClient(endpoint: URL) -> ApolloClient {
  ApolloClient(url: endpoint, defaultRequestConfiguration: RequestConfiguration(requestTimeout: requestTimeout))
}

struct CountriesRepositoryImpl: CountriesRepository {
  let client: any GraphQLClient

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    let filter: GraphQLNullable<CountriesAPI.CountryFilterInput> = SearchPattern.regex(for: term)
      .map { .some(.init(name: .some(.init(regex: .some($0))))) } ?? .none
    let query = CountriesAPI.CountriesQuery(filter: filter)
    var data = try await client.fetch(query, cachePolicy: forceRefresh ? .networkOnly : .cacheFirst)
    // Every country has a name, so no countries for a blank term is a bad response. One from the
    // cache is replaced from the network; one from the network is a server fault.
    if filter == .none, data.countries.isEmpty {
      if !forceRefresh {
        data = try await client.fetch(query, cachePolicy: .networkOnly)
      }
      guard !data.countries.isEmpty else {
        Logger.network.error("\(CountriesAPI.CountriesQuery.operationName, privacy: .public) returned no countries")
        throw CountriesError.server
      }
    }
    // The API sorts by code.
    return data.countries
      .map { CountrySummary(fragment: $0.fragments.countryBasics) }
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  func country(code: String) async throws -> CountryDetails {
    let query = CountriesAPI.CountryQuery(code: code)
    guard let country = try await client.fetch(query, cachePolicy: .cacheFirst).country else {
      let operation = CountriesAPI.CountryQuery.operationName
      Logger.network.error("\(operation, privacy: .public) found no country \(code, privacy: .public)")
      throw CountriesError.notFound
    }
    return CountryDetails(country: country)
  }
}

import Apollo
import CountriesDomain
import Foundation

/// Creates the repository the app uses, backed by the Countries GraphQL API.
///
/// - Parameter requestTimeout: how long a request may wait for data before it fails.
public func makeCountriesRepository(endpoint: URL, requestTimeout: TimeInterval) -> any CountriesRepository {
  CountriesRepositoryImpl(client: ApolloGraphQLClient(client: makeApolloClient(
    endpoint: endpoint,
    requestTimeout: requestTimeout
  )))
}

func makeApolloClient(endpoint: URL, requestTimeout: TimeInterval) -> ApolloClient {
  ApolloClient(url: endpoint, defaultRequestConfiguration: RequestConfiguration(requestTimeout: requestTimeout))
}

struct CountriesRepositoryImpl: CountriesRepository {
  let client: any GraphQLClient

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    let filter: GraphQLNullable<CountriesAPI.CountryFilterInput> = SearchPattern.regex(for: term)
      .map { .some(.init(name: .some(.init(regex: .some($0))))) } ?? .none
    let data = try await client.fetch(
      CountriesAPI.CountriesQuery(filter: filter),
      cachePolicy: forceRefresh ? .networkOnly : .cacheFirst
    )
    // The API sorts by code.
    return data.countries
      .map { CountrySummary(fragment: $0.fragments.countryBasics) }
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }
}

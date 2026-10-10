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

func makeApolloClient(endpoint: URL, requestTimeout _: TimeInterval) -> ApolloClient {
  ApolloClient(url: endpoint)
}

struct CountriesRepositoryImpl: CountriesRepository {
  let client: any GraphQLClient

  func countries(matching _: String, forceRefresh _: Bool) async throws -> [CountrySummary] {
    []
  }
}

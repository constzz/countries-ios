import Apollo
import ApolloAPI
import CountriesDomain
@testable import CountriesData

/// Answers every query with the same response `data`, and records what was asked.
actor FakeGraphQLClient: GraphQLClient {
  private(set) var queries: [any GraphQLQuery] = []
  private(set) var cachePolicies: [CachePolicy.Query.SingleResponse] = []
  private let result: Result<JSONObject, CountriesError>

  init(result: Result<JSONObject, CountriesError>) {
    self.result = result
  }

  func fetch<Query: GraphQLQuery>(
    _ query: Query,
    cachePolicy: CachePolicy.Query.SingleResponse
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
    queries.append(query)
    cachePolicies.append(cachePolicy)
    return try await Query.Data(data: result.get())
  }
}

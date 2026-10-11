import Apollo
import ApolloAPI
import AtlasDomain
@testable import AtlasData

/// Answers each query with the next of its results, repeating the last, and records what was
/// asked.
actor FakeGraphQLClient: GraphQLClient {
  private(set) var queries: [any GraphQLQuery] = []
  private(set) var cachePolicies: [CachePolicy.Query.SingleResponse] = []
  private var results: [Result<JSONObject, RequestError>]

  init(result: Result<JSONObject, RequestError>) {
    self.init(results: [result])
  }

  init(results: [Result<JSONObject, RequestError>]) {
    precondition(!results.isEmpty, "A fake client needs at least one result.")
    self.results = results
  }

  func fetch<Query: GraphQLQuery>(
    _ query: Query,
    cachePolicy: CachePolicy.Query.SingleResponse
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
    queries.append(query)
    cachePolicies.append(cachePolicy)
    let result = results.count > 1 ? results.removeFirst() : results[0]
    return try await Query.Data(data: result.get())
  }
}

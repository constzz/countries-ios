import Apollo
import ApolloAPI
import AtlasDomain
@testable import AtlasData

/// Answers every query with its result, and records what was asked.
actor FakeGraphQLClient: GraphQLClient {
  private(set) var queries: [any GraphQLQuery] = []
  private let result: Result<JSONObject, RequestError>

  init(result: Result<JSONObject, RequestError>) {
    self.result = result
  }

  func fetch<Query: GraphQLQuery>(
    _ query: Query
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
    queries.append(query)
    return try await Query.Data(data: result.get())
  }
}

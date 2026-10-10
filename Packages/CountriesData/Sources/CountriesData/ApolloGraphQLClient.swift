import Apollo
import CountriesDomain

/// Fetches through `ApolloClient` and maps every failure to `CountriesError`.
struct ApolloGraphQLClient: GraphQLClient {
  let client: ApolloClient

  func fetch<Query: GraphQLQuery>(
    _ query: Query,
    cachePolicy: CachePolicy.Query.SingleResponse
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat {
    let response = try await client.fetch(query: query, cachePolicy: cachePolicy)
    return try Self.data(from: response)
  }

  /// The response's data, or `.server` when it has GraphQL errors or no data.
  static func data<Operation>(from response: GraphQLResponse<Operation>) throws -> Operation.Data {
    guard let data = response.data else {
      throw CountriesError.unknown
    }
    return data
  }

  /// The error to throw for a failed fetch: `CancellationError` or a `CountriesError`.
  static func mapped(_: any Error) -> any Error {
    CountriesError.unknown
  }
}

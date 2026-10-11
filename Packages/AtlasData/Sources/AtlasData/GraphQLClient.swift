import Apollo

/// The seam between the repository and Apollo.
protocol GraphQLClient: Sendable {
  /// The query's data. Throws `CountriesError`, or `CancellationError` when cancelled.
  func fetch<Query: GraphQLQuery>(
    _ query: Query,
    cachePolicy: CachePolicy.Query.SingleResponse
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat
}

import Apollo

/// The seam between the remote data source and Apollo.
protocol GraphQLClient: Sendable {
  /// The query's data, fetched from the network. Throws `RequestError`, or `CancellationError` when
  /// cancelled.
  func fetch<Query: GraphQLQuery>(
    _ query: Query
  ) async throws -> Query.Data where Query.ResponseFormat == SingleResponseFormat
}

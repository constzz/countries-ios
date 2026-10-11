import Apollo

/// Apollo's own cache reads and writes, except that a response with GraphQL errors is never
/// written.
///
/// Apollo writes a response's data even when the response also has errors, and a field that failed
/// arrives as `null`. Read back with `.cacheFirst`, a failed `country` would look like an unknown
/// code, and a failed capital like a country without one, until relaunch.
struct ErrorFreeCacheInterceptor: CacheInterceptor {
  private let cache = DefaultCacheInterceptor()

  func readCacheData<Request: GraphQLRequest>(
    from store: ApolloStore,
    request: Request
  ) async throws -> GraphQLResponse<Request.Operation>? {
    try await cache.readCacheData(from: store, request: request)
  }

  func writeCacheData<Request: GraphQLRequest>(
    to store: ApolloStore,
    request: Request,
    response: ParsedResult<Request.Operation>
  ) async throws {
    guard response.result.errors?.isEmpty ?? true else {
      return
    }
    try await cache.writeCacheData(to: store, request: request, response: response)
  }
}

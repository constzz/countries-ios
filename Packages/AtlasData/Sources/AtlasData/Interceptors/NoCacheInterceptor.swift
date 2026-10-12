import Apollo

/// Never reads or writes Apollo's store: the repository caches mapped results itself.
struct NoCacheInterceptor: CacheInterceptor {
  func readCacheData<Request: GraphQLRequest>(
    from _: ApolloStore,
    request _: Request
  ) async throws -> GraphQLResponse<Request.Operation>? {
    nil
  }

  func writeCacheData<Request: GraphQLRequest>(
    to _: ApolloStore,
    request _: Request,
    response _: ParsedResult<Request.Operation>
  ) async throws {}
}

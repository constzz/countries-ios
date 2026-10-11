import Apollo

/// Apollo's default interceptors, with a cache interceptor that keeps responses with GraphQL errors
/// out of the cache.
struct CountriesInterceptorProvider: InterceptorProvider {
  func cacheInterceptor(for _: some GraphQLOperation) -> any CacheInterceptor {
    ErrorFreeCacheInterceptor()
  }
}

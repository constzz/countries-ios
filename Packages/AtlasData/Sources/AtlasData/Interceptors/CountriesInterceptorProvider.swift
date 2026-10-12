import Apollo

/// Apollo's default interceptors, without the cache.
struct CountriesInterceptorProvider: InterceptorProvider {
  func cacheInterceptor(for _: some GraphQLOperation) -> any CacheInterceptor {
    NoCacheInterceptor()
  }
}

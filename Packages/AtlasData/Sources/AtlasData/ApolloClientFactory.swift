import Apollo
import Foundation

/// How long a request may wait for data before it fails, instead of URLSession's 60 s.
private let requestTimeout: TimeInterval = 15

/// The client, which caches nothing: Apollo requires a store, but no request reads or writes it.
func makeApolloClient(
  endpoint: URL,
  session: any ApolloURLSession = URLSession(configuration: .default)
) -> ApolloClient {
  let store = ApolloStore(cache: InMemoryNormalizedCache())
  let transport = RequestChainNetworkTransport(
    urlSession: session,
    interceptorProvider: CountriesInterceptorProvider(),
    store: store,
    endpointURL: endpoint
  )
  return ApolloClient(
    networkTransport: transport,
    store: store,
    defaultRequestConfiguration: RequestConfiguration(requestTimeout: requestTimeout)
  )
}

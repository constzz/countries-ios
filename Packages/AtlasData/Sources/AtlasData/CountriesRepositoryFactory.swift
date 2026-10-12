import AtlasDomain
import Foundation

public func makeCountriesRepository(endpoint: URL) -> any CountriesRepository {
  let client = ApolloGraphQLClient(client: makeApolloClient(endpoint: endpoint))
  return CountriesRepositoryImpl(
    remote: CountriesRemoteDataSourceImpl(client: client),
    summaries: InMemoryCache(),
    details: InMemoryCache()
  )
}

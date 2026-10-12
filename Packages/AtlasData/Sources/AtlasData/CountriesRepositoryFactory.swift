import AtlasDomain
import Foundation

public func makeCountriesRepository(endpoint: URL) -> any CountriesRepository {
  let graphQLClient = ApolloGraphQLClient(apolloClient: makeApolloClient(endpoint: endpoint))
  return CountriesRepositoryImpl(
    remoteDataSource: CountriesRemoteDataSourceImpl(graphQLClient: graphQLClient),
    summariesCache: InMemoryCache(),
    detailsCache: InMemoryCache()
  )
}

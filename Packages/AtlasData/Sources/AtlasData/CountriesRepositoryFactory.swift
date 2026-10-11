import AtlasDomain
import Foundation

public func makeCountriesRepository(endpoint: URL) -> any CountriesRepository {
  CountriesRepositoryImpl(client: ApolloGraphQLClient(client: makeApolloClient(endpoint: endpoint)))
}

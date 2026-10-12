import Apollo
import AtlasDomain
import os

struct CountriesRemoteDataSourceImpl: CountriesRemoteDataSource {
  private let graphQLClient: any GraphQLClient

  init(graphQLClient: any GraphQLClient) {
    self.graphQLClient = graphQLClient
  }

  func countries(matching term: String) async throws -> [CountriesAPI.CountryBasics] {
    let filter: GraphQLNullable<CountriesAPI.CountryFilterInput> = SearchPattern.regex(for: term)
      .map { .some(.init(name: .some(.init(regex: .some($0))))) } ?? .none
    let countries = try await graphQLClient.fetch(CountriesAPI.CountriesQuery(filter: filter)).countries
    // Every country has a name, so no countries for a blank term is a server fault.
    if filter == .none, countries.isEmpty {
      Logger.network.error("\(CountriesAPI.CountriesQuery.operationName, privacy: .public) returned no countries")
      throw RequestError.server
    }
    return countries.map(\.fragments.countryBasics)
  }

  func country(code: String) async throws -> CountriesAPI.CountryQuery.Data.Country? {
    try await graphQLClient.fetch(CountriesAPI.CountryQuery(code: code)).country
  }
}

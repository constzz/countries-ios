import Apollo
import Foundation
import Testing
@testable import AtlasData

@Suite("Apollo client")
struct ApolloClientTests {
  @Test("AC-1.13 requests time out after 15 s")
  func requestsTimeOut() throws {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let sut = makeApolloClient(endpoint: endpoint)

    #expect(sut.defaultRequestConfiguration.requestTimeout == 15)
  }

  @Test("AC-1.8 Apollo's store stays empty, so the repository's cache is the only one")
  func storeStaysEmpty() async throws {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let session = try StubURLSession(bodies: [JSONFixture.responseBody("country-CH")])
    let sut = makeApolloClient(endpoint: endpoint, session: session)
    let query = CountriesAPI.CountryQuery(code: "CH")

    _ = try await sut.fetch(query: query, cachePolicy: .networkOnly)

    #expect(try await sut.store.load(query) == nil)
  }

  @Test("AC-1.8 every fetch reaches the network")
  func everyFetchReachesTheNetwork() async throws {
    let (sut, session) = try makeSUT(responseBodies: [JSONFixture.responseBody("country-CH")])

    _ = try await sut.fetch(CountriesAPI.CountryQuery(code: "CH"))
    _ = try await sut.fetch(CountriesAPI.CountryQuery(code: "CH"))

    #expect(await session.requestCount == 2)
  }

  // MARK: Helpers

  private func makeSUT(
    responseBodies: [Data]
  ) throws -> (sut: ApolloGraphQLClient, session: StubURLSession) {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let session = StubURLSession(bodies: responseBodies)
    return (ApolloGraphQLClient(apolloClient: makeApolloClient(endpoint: endpoint, session: session)), session)
  }
}

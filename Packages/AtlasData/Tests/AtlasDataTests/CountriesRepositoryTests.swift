import Apollo
import AtlasDomain
import Foundation
import Testing
@testable import AtlasData

@Suite("CountriesRepository")
struct CountriesRepositoryTests {
  @Test("AC-1.1 returns every country sorted by name")
  func returnsEveryCountrySortedByName() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.responseData("countries")))

    let countries = try await sut.countries(matching: "", forceRefresh: false)

    #expect(countries.count == 250)
    let names = countries.map(\.name)
    #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    #expect(names.prefix(3) == ["Afghanistan", "Åland", "Albania"])
    #expect(countries.first { $0.code == "CH" }?.continent == Continent(code: "EU", name: "Europe"))
  }

  @Test("AC-1.3 sends the pattern as a name regex filter")
  func sendsThePatternAsANameRegexFilter() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))

    _ = try await sut.countries(matching: " Ger(", forceRefresh: false)

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    let expected = CountriesAPI.CountryFilterInput(name: .some(.init(regex: .some(#"[gG][eE][rR]\("#))))
    #expect(query.filter == .some(expected))
  }

  @Test("AC-1.3 a blank term sends no filter")
  func blankTermSendsNoFilter() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.responseData("countries")))

    _ = try await sut.countries(matching: "  ", forceRefresh: false)

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    #expect(query.filter == .none)
  }

  @Test("AC-1.8 force refresh fetches network-only, otherwise the cache comes first")
  func forceRefreshFetchesNetworkOnly() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.responseData("countries")))

    _ = try await sut.countries(matching: "", forceRefresh: false)
    _ = try await sut.countries(matching: "", forceRefresh: true)

    #expect(await client.cachePolicies == [.cacheFirst, .networkOnly])
  }

  @Test("AC-1.6 a blank term with no countries refetches from the network")
  func blankTermWithNoCountriesRefetches() async throws {
    let (sut, client) = try makeSUT(results: [
      .success(JSONFixture.object(#"{ "countries": [] }"#)),
      .success(JSONFixture.responseData("countries")),
    ])

    let countries = try await sut.countries(matching: "", forceRefresh: false)

    #expect(countries.count == 250)
    #expect(await client.cachePolicies == [.cacheFirst, .networkOnly])
  }

  @Test("AC-1.6 a blank term with no countries from the network is a server error")
  func blankTermWithNoCountriesIsAServerError() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))

    await #expect(throws: RequestError.server) {
      try await sut.countries(matching: " ", forceRefresh: false)
    }
    await #expect(throws: RequestError.server) {
      try await sut.countries(matching: "", forceRefresh: true)
    }
    #expect(await client.cachePolicies == [.cacheFirst, .networkOnly, .networkOnly])
  }

  @Test("AC-1.6 errors reach the caller unchanged")
  func errorsPropagate() async {
    let (sut, _) = makeSUT(result: .failure(.offline))

    await #expect(throws: RequestError.offline) {
      try await sut.countries(matching: "", forceRefresh: false)
    }
  }

  // MARK: One country

  @Test("AC-2.2 fetches the country by code, cache first")
  func fetchesTheCountryByCode() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.responseData("country-CH")))

    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(details.currencies == ["CHE", "CHF", "CHW"])
    let query = try #require(await client.queries.first as? CountriesAPI.CountryQuery)
    #expect(query.code == "CH")
    #expect(await client.cachePolicies == [.cacheFirst])
  }

  @Test("AC-2.5 a null country is not found")
  func nullCountryIsNotFound() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.responseData("country-unknown")))

    await #expect(throws: RequestError.notFound) {
      try await sut.country(code: "XX")
    }
  }

  @Test("AC-2.4 a failure reaches the caller unchanged")
  func countryFailurePropagates() async {
    let (sut, _) = makeSUT(result: .failure(.offline))

    await #expect(throws: RequestError.offline) {
      try await sut.country(code: "CH")
    }
  }

  // MARK: Client

  @Test("AC-1.13 requests time out after 15 s")
  func requestsTimeOut() throws {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let sut = makeApolloClient(endpoint: endpoint)

    #expect(sut.defaultRequestConfiguration.requestTimeout == 15)
  }

  @Test("AC-2.2 a country already fetched comes from the cache")
  func fetchedCountryComesFromTheCache() async throws {
    let (sut, session) = try makeSUT(responseBodies: [JSONFixture.responseBody("country-CH")])

    _ = try await sut.country(code: "CH")
    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(await session.requestCount == 1)
  }

  /// Apollo writes a response's data even when it has errors, and a failed field arrives as null:
  /// read back, it would make Try Again show "Country Not Found".
  @Test("AC-2.4 a response with GraphQL errors stays out of the cache")
  func responseWithErrorsStaysOutOfTheCache() async throws {
    let failed = Data(#"{ "data": { "country": null }, "errors": [{ "message": "Internal error" }] }"#.utf8)
    let (sut, session) = try makeSUT(responseBodies: [failed, JSONFixture.responseBody("country-CH")])
    await #expect(throws: RequestError.server) {
      try await sut.country(code: "CH")
    }

    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(await session.requestCount == 2)
  }

  // MARK: Helpers

  private func makeSUT(
    result: Result<JSONObject, RequestError>
  ) -> (sut: CountriesRepositoryImpl, client: FakeGraphQLClient) {
    makeSUT(results: [result])
  }

  private func makeSUT(
    results: [Result<JSONObject, RequestError>]
  ) -> (sut: CountriesRepositoryImpl, client: FakeGraphQLClient) {
    let client = FakeGraphQLClient(results: results)
    return (CountriesRepositoryImpl(client: client), client)
  }

  /// The repository over a real `ApolloClient`, cache included, whose requests are answered with
  /// `responseBodies`.
  private func makeSUT(
    responseBodies: [Data]
  ) throws -> (sut: CountriesRepositoryImpl, session: StubURLSession) {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let session = StubURLSession(bodies: responseBodies)
    let client = makeApolloClient(endpoint: endpoint, session: session)
    return (CountriesRepositoryImpl(client: ApolloGraphQLClient(client: client)), session)
  }
}

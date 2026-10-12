import Apollo
import AtlasDomain
import Testing
@testable import AtlasData

@Suite("CountriesRemoteDataSource")
struct CountriesRemoteDataSourceTests {
  @Test("AC-1.1 returns every country")
  func returnsEveryCountry() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.responseData("countries")))

    let countries = try await sut.countries(matching: "")

    #expect(countries.count == 250)
    #expect(countries.first { $0.code == "CH" }?.name == "Switzerland")
  }

  @Test("AC-1.3 sends the pattern as a name regex filter")
  func sendsThePatternAsANameRegexFilter() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))

    _ = try await sut.countries(matching: " Ger(")

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    let expected = CountriesAPI.CountryFilterInput(name: .some(.init(regex: .some(#"[gG][eE][rR]\("#))))
    #expect(query.filter == .some(expected))
  }

  @Test("AC-1.3 a blank term sends no filter")
  func blankTermSendsNoFilter() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.responseData("countries")))

    _ = try await sut.countries(matching: "  ")

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    #expect(query.filter == .none)
  }

  @Test("AC-1.5 a search with no match returns no countries")
  func searchWithNoMatchReturnsNone() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))

    let countries = try await sut.countries(matching: "zz")

    #expect(countries.isEmpty)
  }

  @Test("AC-1.6 no countries for a blank term is a server error")
  func blankTermWithNoCountriesIsAServerError() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))

    await #expect(throws: RequestError.server) {
      try await sut.countries(matching: " ")
    }
  }

  @Test("AC-1.6 errors reach the caller unchanged")
  func errorsPropagate() async {
    let (sut, _) = makeSUT(result: .failure(.offline))

    await #expect(throws: RequestError.offline) {
      try await sut.countries(matching: "")
    }
  }

  // MARK: One country

  @Test("AC-2.2 fetches the country by code")
  func fetchesTheCountryByCode() async throws {
    let (sut, client) = try makeSUT(result: .success(JSONFixture.responseData("country-CH")))

    let country = try await sut.country(code: "CH")

    #expect(country?.capital == "Bern")
    let query = try #require(await client.queries.first as? CountriesAPI.CountryQuery)
    #expect(query.code == "CH")
  }

  @Test("AC-2.5 a null country is nil")
  func nullCountryIsNil() async throws {
    let (sut, _) = try makeSUT(result: .success(JSONFixture.responseData("country-unknown")))

    #expect(try await sut.country(code: "XX") == nil)
  }

  @Test("AC-2.4 a failure reaches the caller unchanged")
  func countryFailurePropagates() async {
    let (sut, _) = makeSUT(result: .failure(.offline))

    await #expect(throws: RequestError.offline) {
      try await sut.country(code: "CH")
    }
  }

  // MARK: Helpers

  private func makeSUT(
    result: Result<JSONObject, RequestError>
  ) -> (sut: CountriesRemoteDataSourceImpl, client: FakeGraphQLClient) {
    let client = FakeGraphQLClient(result: result)
    return (CountriesRemoteDataSourceImpl(client: client), client)
  }
}

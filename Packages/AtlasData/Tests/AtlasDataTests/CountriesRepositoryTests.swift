import Apollo
import AtlasDomain
import Foundation
import Testing
@testable import AtlasData

@Suite("CountriesRepository")
struct CountriesRepositoryTests {
  @Test("AC-1.1 maps every country the data source returns")
  func mapsEveryCountry() async throws {
    let (sut, _) = try await makeSUT(countries: [.success(fixtureCountries())])

    let countries = try await sut.countries(matching: "", forceRefresh: false)

    #expect(countries.count == 250)
    #expect(countries.first { $0.code == "CH" }?.continent == Continent(code: "EU", name: "Europe"))
  }

  @Test("AC-1.3 asks the data source for the trimmed term")
  func asksForTheTrimmedTerm() async throws {
    let (sut, remoteDataSource) = makeSUT()

    _ = try await sut.countries(matching: " ger ", forceRefresh: false)

    #expect(await remoteDataSource.requestedTerms == ["ger"])
  }

  @Test("AC-1.8 a term already fetched comes from the cache")
  func termAlreadyFetchedComesFromTheCache() async throws {
    let (sut, remoteDataSource) = try await makeSUT(countries: [.success(fixtureCountries())])

    _ = try await sut.countries(matching: "", forceRefresh: false)
    let countries = try await sut.countries(matching: " ", forceRefresh: false)

    #expect(countries.count == 250)
    #expect(await remoteDataSource.requestedTerms == [""])
  }

  @Test("AC-1.3 each term is cached on its own")
  func eachTermIsCachedOnItsOwn() async throws {
    let (sut, remoteDataSource) = makeSUT()

    for term in ["a", "b", "a"] {
      _ = try await sut.countries(matching: term, forceRefresh: false)
    }

    #expect(await remoteDataSource.requestedTerms == ["a", "b"])
  }

  @Test("AC-1.8 force refresh fetches again and replaces the cached countries")
  func forceRefreshReplacesTheCachedCountries() async throws {
    let all = try await fixtureCountries()
    let (sut, remoteDataSource) = makeSUT(countries: [.success(Array(all.prefix(2))), .success(Array(all.prefix(1)))])

    _ = try await sut.countries(matching: "a", forceRefresh: false)
    let refreshed = try await sut.countries(matching: "a", forceRefresh: true)
    let cached = try await sut.countries(matching: "a", forceRefresh: false)

    #expect(refreshed.count == 1)
    #expect(cached == refreshed)
    #expect(await remoteDataSource.requestedTerms == ["a", "a"])
  }

  @Test("AC-1.6 a failure reaches the caller and isn't cached")
  func failureIsNotCached() async throws {
    let (sut, remoteDataSource) = try await makeSUT(countries: [.failure(.offline), .success(fixtureCountries())])

    await #expect(throws: RequestError.offline) {
      try await sut.countries(matching: "", forceRefresh: false)
    }
    let countries = try await sut.countries(matching: "", forceRefresh: false)

    #expect(countries.count == 250)
    #expect(await remoteDataSource.requestedTerms == ["", ""])
  }

  // MARK: One country

  @Test("AC-2.2 maps the country, and serves it from the cache after that")
  func countryComesFromTheCacheAfterThat() async throws {
    let (sut, remoteDataSource) = try await makeSUT(country: [.success(fixtureCountry("country-CH"))])

    _ = try await sut.country(code: "CH")
    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(details.currencies == ["CHE", "CHF", "CHW"])
    #expect(await remoteDataSource.requestedCodes == ["CH"])
  }

  @Test("AC-2.5 an unknown code is not found, and isn't cached")
  func unknownCodeIsNotFound() async {
    let (sut, remoteDataSource) = makeSUT(country: [.success(nil)])

    for _ in 1 ... 2 {
      await #expect(throws: RequestError.notFound) {
        try await sut.country(code: "XX")
      }
    }

    #expect(await remoteDataSource.requestedCodes == ["XX", "XX"])
  }

  @Test("AC-2.4 a failure reaches the caller and isn't cached")
  func countryFailureIsNotCached() async throws {
    let (sut, remoteDataSource) = try await makeSUT(country: [
      .failure(.offline),
      .success(fixtureCountry("country-CH")),
    ])

    await #expect(throws: RequestError.offline) {
      try await sut.country(code: "CH")
    }
    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(await remoteDataSource.requestedCodes == ["CH", "CH"])
  }

  // MARK: Over Apollo

  @Test("AC-2.2 a country already fetched makes no second request")
  func fetchedCountryMakesNoSecondRequest() async throws {
    let (sut, session) = try makeSUT(responseBodies: [JSONFixture.responseBody("country-CH")])

    _ = try await sut.country(code: "CH")
    let details = try await sut.country(code: "CH")

    #expect(details.summary.name == "Switzerland")
    #expect(await session.requestCount == 1)
  }

  @Test("AC-2.4 a response with GraphQL errors isn't cached, so Try Again reaches the network")
  func responseWithErrorsIsNotCached() async throws {
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
    countries: [Result<[CountriesAPI.CountryBasics], RequestError>] = [.success([])],
    country: [Result<CountriesAPI.CountryQuery.Data.Country?, RequestError>] = [.success(nil)]
  ) -> (sut: CountriesRepositoryImpl, remoteDataSource: FakeCountriesRemoteDataSource) {
    let remoteDataSource = FakeCountriesRemoteDataSource(countries: countries, country: country)
    let sut = CountriesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      summariesCache: InMemoryCache(),
      detailsCache: InMemoryCache()
    )
    return (sut, remoteDataSource)
  }

  /// The repository over a real `ApolloClient`, whose requests are answered with `responseBodies`.
  private func makeSUT(
    responseBodies: [Data]
  ) throws -> (sut: CountriesRepositoryImpl, session: StubURLSession) {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let session = StubURLSession(bodies: responseBodies)
    let graphQLClient = ApolloGraphQLClient(apolloClient: makeApolloClient(endpoint: endpoint, session: session))
    let sut = CountriesRepositoryImpl(
      remoteDataSource: CountriesRemoteDataSourceImpl(graphQLClient: graphQLClient),
      summariesCache: InMemoryCache(),
      detailsCache: InMemoryCache()
    )
    return (sut, session)
  }

  private func fixtureCountries() async throws -> [CountriesAPI.CountryBasics] {
    try await CountriesAPI.CountriesQuery.Data(data: JSONFixture.responseData("countries")).countries
      .map(\.fragments.countryBasics)
  }

  private func fixtureCountry(_ name: String) async throws -> CountriesAPI.CountryQuery.Data.Country? {
    try await CountriesAPI.CountryQuery.Data(data: JSONFixture.responseData(name)).country
  }
}

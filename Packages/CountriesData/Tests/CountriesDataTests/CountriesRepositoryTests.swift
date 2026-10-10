import Apollo
import CountriesDomain
import Foundation
import Testing
@testable import CountriesData

@Suite("CountriesRepository")
struct CountriesRepositoryTests {
  @Test("AC-1.1 returns every country sorted by name")
  func returnsEveryCountrySortedByName() async throws {
    let client = try FakeGraphQLClient(result: .success(JSONFixture.responseData("countries")))
    let repository = CountriesRepositoryImpl(client: client)

    let countries = try await repository.countries(matching: "", forceRefresh: false)

    #expect(countries.count == 250)
    let names = countries.map(\.name)
    #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    #expect(names.prefix(3) == ["Afghanistan", "Åland", "Albania"])
    #expect(countries.first { $0.code == "CH" }?.continent == Continent(code: "EU", name: "Europe"))
  }

  @Test("AC-1.3 sends the pattern as a name regex filter")
  func sendsThePatternAsANameRegexFilter() async throws {
    let client = try FakeGraphQLClient(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))
    let repository = CountriesRepositoryImpl(client: client)

    _ = try await repository.countries(matching: " Ger(", forceRefresh: false)

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    let expected = CountriesAPI.CountryFilterInput(name: .some(.init(regex: .some(#"[gG][eE][rR]\("#))))
    #expect(query.filter == .some(expected))
  }

  @Test("AC-1.3 a blank term sends no filter")
  func blankTermSendsNoFilter() async throws {
    let client = try FakeGraphQLClient(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))
    let repository = CountriesRepositoryImpl(client: client)

    _ = try await repository.countries(matching: "  ", forceRefresh: false)

    let query = try #require(await client.queries.first as? CountriesAPI.CountriesQuery)
    #expect(query.filter == .none)
  }

  @Test("AC-1.8 force refresh fetches network-only, otherwise the cache comes first")
  func forceRefreshFetchesNetworkOnly() async throws {
    let client = try FakeGraphQLClient(result: .success(JSONFixture.object(#"{ "countries": [] }"#)))
    let repository = CountriesRepositoryImpl(client: client)

    _ = try await repository.countries(matching: "", forceRefresh: false)
    _ = try await repository.countries(matching: "", forceRefresh: true)

    #expect(await client.cachePolicies == [.cacheFirst, .networkOnly])
  }

  @Test("AC-1.6 errors reach the caller unchanged")
  func errorsPropagate() async {
    let repository = CountriesRepositoryImpl(client: FakeGraphQLClient(result: .failure(.offline)))

    await #expect(throws: CountriesError.offline) {
      try await repository.countries(matching: "", forceRefresh: false)
    }
  }

  @Test("AC-1.13 requests time out after 15 s")
  func requestsTimeOut() throws {
    let endpoint = try #require(URL(string: "https://countries.example/graphql"))
    let client = makeApolloClient(endpoint: endpoint)
    #expect(client.defaultRequestConfiguration.requestTimeout == 15)
  }
}

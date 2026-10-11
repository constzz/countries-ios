import AtlasDomain
import Testing
@testable import AtlasData

@Suite("CountrySummary mapping")
struct CountrySummaryMappingTests {
  @Test("AC-1.1 maps the fragment to a summary")
  func mapsTheFragment() async throws {
    let data = try await CountriesAPI.CountriesQuery.Data(data: JSONFixture.object("""
    {
      "countries": [{
        "__typename": "Country",
        "code": "CH",
        "name": "Switzerland",
        "emoji": "🇨🇭",
        "continent": { "__typename": "Continent", "code": "EU", "name": "Europe" }
      }]
    }
    """))

    let summaries = data.countries.map { CountrySummary(fragment: $0.fragments.countryBasics) }

    #expect(summaries == [
      CountrySummary(code: "CH", name: "Switzerland", emoji: "🇨🇭", continent: Continent(code: "EU", name: "Europe")),
    ])
  }
}

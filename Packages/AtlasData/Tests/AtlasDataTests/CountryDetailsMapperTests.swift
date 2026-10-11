import AtlasDomain
import Testing
@testable import AtlasData

@Suite("CountryDetailsMapper")
struct CountryDetailsMapperTests {
  @Test("AC-2.2 maps every field and reuses the summary mapper")
  func mapsEveryField() async throws {
    let country = try await country(JSONFixture.responseData("country-CH"))

    let details = CountryDetailsMapper.map(country)

    #expect(details == CountryDetails(
      summary: CountrySummaryMapper.map(country.fragments.countryBasics),
      capital: "Bern",
      currencies: ["CHE", "CHF", "CHW"],
      languages: [
        Language(code: "de", name: "German"),
        Language(code: "fr", name: "French"),
        Language(code: "it", name: "Italian"),
      ]
    ))
    #expect(details.summary == CountrySummary(
      code: "CH", name: "Switzerland", emoji: "🇨🇭", continent: Continent(code: "EU", name: "Europe")
    ))
  }

  @Test("AC-2.3 Antarctica has no capital, currencies or languages")
  func antarcticaHasNoCapitalCurrenciesOrLanguages() async throws {
    let details = try await CountryDetailsMapper.map(country(JSONFixture.responseData("country-AQ")))

    #expect(details.summary.name == "Antarctica")
    #expect(details.capital == nil)
    #expect(details.currencies.isEmpty)
    #expect(details.languages.isEmpty)
  }

  @Test("AC-2.3 blank values are missing values")
  func blankValuesAreMissing() async throws {
    let details = try await CountryDetailsMapper.map(country(JSONFixture.object("""
    {
      "country": {
        "__typename": "Country",
        "code": "XY",
        "name": "Blankland",
        "emoji": "🏳️",
        "continent": { "__typename": "Continent", "code": "EU", "name": "Europe" },
        "capital": " ",
        "currencies": ["", "EUR", " "],
        "languages": [
          { "__typename": "Language", "code": "xx", "name": " " },
          { "__typename": "Language", "code": "en", "name": "English" }
        ]
      }
    }
    """)))

    #expect(details.capital == nil)
    #expect(details.currencies == ["EUR"])
    #expect(details.languages == [Language(code: "en", name: "English")])
  }

  private func country(_ data: JSONObject) async throws -> CountriesAPI.CountryQuery.Data.Country {
    try #require(await CountriesAPI.CountryQuery.Data(data: data).country)
  }
}

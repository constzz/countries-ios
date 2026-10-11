import CountriesDomain
import Testing

@Suite("CountryDetails")
struct CountryDetailsTests {
  @Test("AC-2.2 details are identified by the country code")
  func idIsCode() {
    let details = CountryDetails(
      summary: CountrySummary(
        code: "CH", name: "Switzerland", emoji: "🇨🇭", continent: Continent(code: "EU", name: "Europe")
      ),
      capital: "Bern",
      currencies: ["CHF"],
      languages: [Language(code: "de", name: "German")]
    )
    #expect(details.id == "CH")
  }
}

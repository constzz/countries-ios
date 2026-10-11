import AtlasDomain
import Testing

@Suite("CountrySummary")
struct CountrySummaryTests {
  @Test("AC-1.7 a summary's id is its code")
  func idIsCode() {
    let sut = CountrySummary(
      code: "CH", name: "Switzerland", emoji: "🇨🇭", continent: Continent(code: "EU", name: "Europe")
    )

    #expect(sut.id == "CH")
  }
}

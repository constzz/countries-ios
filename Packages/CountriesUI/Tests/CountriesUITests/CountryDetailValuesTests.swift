import CountriesDomain
import Foundation
import Testing
@testable import CountriesUI

@Suite("Country detail values")
struct CountryDetailValuesTests {
  private let english = Locale(identifier: "en_US")

  @Test("AC-2.2 every row shows its value")
  func everyRowShowsItsValue() {
    let values = CountryDetailValues(.southGeorgia, locale: english)

    #expect(values == CountryDetailValues(
      capital: "King Edward Point",
      currencies: "GBP",
      languages: "English",
      continent: "Antarctica"
    ))
  }

  @Test("AC-2.3 missing values read None")
  func missingValuesReadNone() {
    let values = CountryDetailValues(.antarctica, locale: english)

    let none = String(localized: .countryDetailNone)
    #expect(values.capital == none)
    #expect(values.currencies == none)
    #expect(values.languages == none)
    #expect(values.continent == "Antarctica")
  }

  @Test("AC-2.7 currencies and languages use the locale's list format")
  func listsUseTheLocalesListFormat() {
    let english = CountryDetailValues(.switzerland, locale: english)
    let german = CountryDetailValues(.switzerland, locale: Locale(identifier: "de_DE"))

    #expect(english.currencies == "CHE, CHF, and CHW")
    #expect(english.languages == "German, French, and Italian")
    #expect(german.currencies == "CHE, CHF und CHW")
  }
}

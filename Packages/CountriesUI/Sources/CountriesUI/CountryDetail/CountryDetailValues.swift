import CountriesDomain
import Foundation

/// The text of each detail row. A missing value reads "None", and lists use the locale's list
/// format.
struct CountryDetailValues: Equatable {
  let capital: String
  let currencies: String
  let languages: String
  let continent: String
}

extension CountryDetailValues {
  init(_: CountryDetails, locale _: Locale = .current) {
    self.init(capital: "", currencies: "", languages: "", continent: "")
  }
}

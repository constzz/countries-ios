import CountriesDomain
import Foundation

/// The text of each detail row. A missing value reads "None", and lists use the locale's list
/// format. Values from the API are shown as the API spells them.
struct CountryDetailValues: Equatable {
  let capital: String
  let currencies: String
  let languages: String
  let continent: String
}

extension CountryDetailValues {
  init(_ details: CountryDetails, locale: Locale = .current) {
    let none = String(
      localized: "None",
      bundle: .module,
      locale: locale,
      comment: "Value of a country detail row that has no value, such as the capital of Antarctica."
    )
    func list(_ items: [String]) -> String {
      items.isEmpty ? none : items.formatted(.list(type: .and).locale(locale))
    }
    self.init(
      capital: details.capital ?? none,
      currencies: list(details.currencies),
      languages: list(details.languages.map(\.name)),
      continent: details.summary.continent.name
    )
  }
}

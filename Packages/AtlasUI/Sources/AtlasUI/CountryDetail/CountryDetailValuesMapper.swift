import AtlasDomain
import Foundation

/// A missing value reads "None", and lists use the locale's list format. Values from the API are
/// shown as the API spells them.
final class CountryDetailValuesMapper {
  private init() {}

  /// - Parameter locale: the view's `\.locale`, so the values match the rest of the screen.
  static func map(_ details: CountryDetails, locale: Locale) -> CountryDetailValues {
    var noneResource = LocalizedStringResource.countryDetailNone
    noneResource.locale = locale
    let none = String(localized: noneResource)
    func list(_ items: [String]) -> String {
      items.isEmpty ? none : items.formatted(.list(type: .and).locale(locale))
    }
    return CountryDetailValues(
      capital: details.capital ?? none,
      currencies: list(details.currencies),
      languages: list(details.languages.map(\.name)),
      continent: details.summary.continent.name
    )
  }
}

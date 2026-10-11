import CountriesDomain

extension CountryDetails {
  /// Maps the detail query's country. The summary fields go through the list's mapper. Blank
  /// values are missing values: Antarctica's currencies are `[""]`.
  init(country: CountriesAPI.CountryQuery.Data.Country) {
    self.init(
      summary: CountrySummary(fragment: country.fragments.countryBasics),
      capital: country.capital.flatMap { $0.isBlank ? nil : $0 },
      currencies: country.currencies.filter { !$0.isBlank },
      languages: country.languages
        .filter { !$0.name.isBlank }
        .map { Language(code: $0.code, name: $0.name) }
    )
  }
}

private extension String {
  var isBlank: Bool {
    allSatisfy(\.isWhitespace)
  }
}

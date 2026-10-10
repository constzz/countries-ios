import CountriesDomain

extension CountryDetails {
  /// Maps the detail query's country. The summary fields go through the list's mapper.
  init(country: CountriesAPI.CountryQuery.Data.Country) {
    self.init(
      summary: CountrySummary(fragment: country.fragments.countryBasics),
      capital: nil,
      currencies: [],
      languages: []
    )
  }
}

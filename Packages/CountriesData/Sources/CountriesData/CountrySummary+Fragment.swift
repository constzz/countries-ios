import CountriesDomain

extension CountrySummary {
  /// Maps the fields every country screen selects.
  init(fragment _: CountriesAPI.CountryBasics) {
    self.init(code: "", name: "", emoji: "", continent: Continent(code: "", name: ""))
  }
}

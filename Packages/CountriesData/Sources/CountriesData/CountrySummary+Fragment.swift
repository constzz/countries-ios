import CountriesDomain

extension CountrySummary {
  init(fragment: CountriesAPI.CountryBasics) {
    self.init(
      code: fragment.code,
      name: fragment.name,
      emoji: fragment.emoji,
      continent: Continent(code: fragment.continent.code, name: fragment.continent.name)
    )
  }
}

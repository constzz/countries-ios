import AtlasDomain

final class CountrySummaryMapper {
  private init() {}

  static func map(_ fragment: CountriesAPI.CountryBasics) -> CountrySummary {
    CountrySummary(
      code: fragment.code,
      name: fragment.name,
      emoji: fragment.emoji,
      continent: Continent(code: fragment.continent.code, name: fragment.continent.name)
    )
  }
}

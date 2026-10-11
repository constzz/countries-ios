#if DEBUG
  import AtlasDomain

  extension CountrySummary {
    /// Countries for previews, snapshots and tests, sorted by name. They cover every continent, a
    /// name with a diacritic and the longest name the API returns.
    static let samples: [CountrySummary] = [
      sample("AF", "Afghanistan", "🇦🇫", .asia),
      sample("AX", "Åland", "🇦🇽", .europe),
      sample("AQ", "Antarctica", "🇦🇶", .antarctica),
      sample("BO", "Bolivia", "🇧🇴", .southAmerica),
      sample("BR", "Brazil", "🇧🇷", .southAmerica),
      sample("CA", "Canada", "🇨🇦", .northAmerica),
      sample("DE", "Germany", "🇩🇪", .europe),
      sample("JP", "Japan", "🇯🇵", .asia),
      sample("KE", "Kenya", "🇰🇪", .africa),
      sample("NZ", "New Zealand", "🇳🇿", .oceania),
      sample("GS", "South Georgia and the South Sandwich Islands", "🇬🇸", .antarctica),
      sample("CH", "Switzerland", "🇨🇭", .europe),
      sample("US", "United States", "🇺🇸", .northAmerica),
    ]

    private static func sample(_ code: String, _ name: String, _ emoji: String, _ continent: Continent) -> Self {
      CountrySummary(code: code, name: name, emoji: emoji, continent: continent)
    }
  }

  private extension Continent {
    static let africa = Continent(code: "AF", name: "Africa")
    static let antarctica = Continent(code: "AN", name: "Antarctica")
    static let asia = Continent(code: "AS", name: "Asia")
    static let europe = Continent(code: "EU", name: "Europe")
    static let northAmerica = Continent(code: "NA", name: "North America")
    static let oceania = Continent(code: "OC", name: "Oceania")
    static let southAmerica = Continent(code: "SA", name: "South America")
  }
#endif

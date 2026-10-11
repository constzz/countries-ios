#if DEBUG
  import CountriesDomain

  extension CountryDetails {
    /// Every row filled, with two currencies and three languages. Its row is near the top of the
    /// list, so the selection shows on every iPad preset.
    static let bolivia = sample(
      "BO",
      capital: "Sucre",
      currencies: ["BOB", "BOV"],
      languages: [("es", "Spanish"), ("ay", "Aymara"), ("qu", "Quechua")]
    )

    /// Every row filled, with three currencies and three languages.
    static let switzerland = sample(
      "CH",
      capital: "Bern",
      currencies: ["CHE", "CHF", "CHW"],
      languages: [("de", "German"), ("fr", "French"), ("it", "Italian")]
    )

    /// No capital, currencies or languages.
    static let antarctica = sample("AQ", capital: nil, currencies: [], languages: [])

    /// The longest name the API returns.
    static let southGeorgia = sample(
      "GS",
      capital: "King Edward Point",
      currencies: ["GBP"],
      languages: [("en", "English")]
    )

    /// Details as the live API returned them on 2026-10-10, for a country in
    /// `CountrySummary.samples`.
    private static func sample(
      _ code: String,
      capital: String?,
      currencies: [String],
      languages: [(code: String, name: String)]
    ) -> Self {
      guard let summary = CountrySummary.samples.first(where: { $0.code == code }) else {
        preconditionFailure("No sample summary for \(code)")
      }
      return CountryDetails(
        summary: summary,
        capital: capital,
        currencies: currencies,
        languages: languages.map { Language(code: $0.code, name: $0.name) }
      )
    }
  }
#endif

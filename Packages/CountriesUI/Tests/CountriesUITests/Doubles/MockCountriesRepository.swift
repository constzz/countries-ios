import CountriesDomain

/// Records every request and answers with a scripted result.
actor MockCountriesRepository: CountriesRepository {
  struct Call: Equatable {
    let term: String
    let forceRefresh: Bool
  }

  private(set) var calls: [Call] = []
  private var result: Result<[CountrySummary], CountriesError>

  init(result: Result<[CountrySummary], CountriesError> = .success([])) {
    self.result = result
  }

  func setResult(_ result: Result<[CountrySummary], CountriesError>) {
    self.result = result
  }

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    calls.append(Call(term: term, forceRefresh: forceRefresh))
    return try result.get()
  }

  func country(code _: String) async throws -> CountryDetails {
    throw CountriesError.unknown
  }
}

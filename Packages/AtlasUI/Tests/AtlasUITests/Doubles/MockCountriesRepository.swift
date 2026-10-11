import AtlasDomain

/// Records every request and answers with a scripted result.
actor MockCountriesRepository: CountriesRepository {
  struct Call: Equatable {
    let term: String
    let forceRefresh: Bool
  }

  private(set) var calls: [Call] = []
  /// The codes `country(code:)` was asked for, in order.
  private(set) var requestedCodes: [String] = []
  private var result: Result<[CountrySummary], CountriesError>
  private var detailResult: Result<CountryDetails, CountriesError>

  init(
    result: Result<[CountrySummary], CountriesError> = .success([]),
    detailResult: Result<CountryDetails, CountriesError> = .failure(.notFound)
  ) {
    self.result = result
    self.detailResult = detailResult
  }

  func setResult(_ result: Result<[CountrySummary], CountriesError>) {
    self.result = result
  }

  func setDetailResult(_ detailResult: Result<CountryDetails, CountriesError>) {
    self.detailResult = detailResult
  }

  func countries(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    calls.append(Call(term: term, forceRefresh: forceRefresh))
    return try result.get()
  }

  func country(code: String) async throws -> CountryDetails {
    requestedCodes.append(code)
    return try detailResult.get()
  }
}

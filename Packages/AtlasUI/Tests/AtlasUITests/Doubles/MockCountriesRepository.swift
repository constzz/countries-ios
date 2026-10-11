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
  private var result: Result<[CountrySummary], RequestError>
  private var detailResult: Result<CountryDetails, RequestError>

  init(
    result: Result<[CountrySummary], RequestError> = .success([]),
    detailResult: Result<CountryDetails, RequestError> = .failure(.notFound)
  ) {
    self.result = result
    self.detailResult = detailResult
  }

  func setResult(_ result: Result<[CountrySummary], RequestError>) {
    self.result = result
  }

  func setDetailResult(_ detailResult: Result<CountryDetails, RequestError>) {
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

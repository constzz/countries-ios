public struct GetCountryDetailsUseCase: Sendable {
  private let repository: any CountriesRepository

  public init(repository: any CountriesRepository) {
    self.repository = repository
  }

  public func callAsFunction(code: String) async throws -> CountryDetails {
    try await repository.country(code: code)
  }
}

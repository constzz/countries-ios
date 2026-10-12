import AtlasDomain
import Testing

@Suite("GetCountryDetailsUseCase")
struct GetCountryDetailsUseCaseTests {
  @Test("AC-2.2 fetches the country by code")
  func fetchesTheCountryByCode() async throws {
    let details = CountryDetails(
      summary: CountrySummary(
        code: "CH", name: "Switzerland", emoji: "🇨🇭", continent: Continent(code: "EU", name: "Europe")
      ),
      capital: "Bern",
      currencies: ["CHF"],
      languages: [Language(code: "de", name: "German")]
    )
    let (sut, repository) = makeSUT(detailResult: .success(details))

    let fetched = try await sut(code: "CH")

    #expect(fetched == details)
    #expect(await repository.requestedCodes == ["CH"])
  }

  @Test("AC-2.5 not found reaches the caller unchanged")
  func notFoundPropagates() async {
    let (sut, _) = makeSUT(detailResult: .failure(.notFound))

    await #expect(throws: RequestError.notFound) {
      try await sut(code: "XX")
    }
  }

  // MARK: Helpers

  private func makeSUT(
    detailResult: Result<CountryDetails, RequestError>
  ) -> (sut: GetCountryDetailsUseCase, repository: MockCountriesRepository) {
    let repository = MockCountriesRepository(detailResult: detailResult)
    return (GetCountryDetailsUseCase(repository: repository), repository)
  }
}

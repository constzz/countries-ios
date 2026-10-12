import AtlasDomain
import Testing

@Suite("GetCountriesUseCase")
struct GetCountriesUseCaseTests {
  @Test("AC-1.1 countries are sorted by name")
  func sortsByName() async throws {
    let (sut, _) = makeSUT(result: .success(["Switzerland", "Albania", "Åland", "Afghanistan"].map(country(named:))))

    let countries = try await sut(matching: "", forceRefresh: false)

    #expect(countries.map(\.name) == ["Afghanistan", "Åland", "Albania", "Switzerland"])
  }

  @Test("AC-1.8 passes the term and force refresh to the repository")
  func passesTheRequestOn() async throws {
    let (sut, repository) = makeSUT()

    _ = try await sut(matching: "ger", forceRefresh: true)

    #expect(await repository.calls == [MockCountriesRepository.Call(term: "ger", forceRefresh: true)])
  }

  @Test("AC-1.6 errors reach the caller unchanged")
  func errorsPropagate() async {
    let (sut, _) = makeSUT(result: .failure(.offline))

    await #expect(throws: RequestError.offline) {
      try await sut(matching: "", forceRefresh: false)
    }
  }

  // MARK: Helpers

  private func makeSUT(
    result: Result<[CountrySummary], RequestError> = .success([])
  ) -> (sut: GetCountriesUseCase, repository: MockCountriesRepository) {
    let repository = MockCountriesRepository(result: result)
    return (GetCountriesUseCase(repository: repository), repository)
  }

  private func country(named name: String) -> CountrySummary {
    CountrySummary(code: name, name: name, emoji: "", continent: Continent(code: "EU", name: "Europe"))
  }
}

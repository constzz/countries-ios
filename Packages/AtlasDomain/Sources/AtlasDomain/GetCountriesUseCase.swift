import Foundation

public struct GetCountriesUseCase: Sendable {
  private let repository: any CountriesRepository

  public init(repository: any CountriesRepository) {
    self.repository = repository
  }

  public func callAsFunction(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    try await repository.countries(matching: term, forceRefresh: forceRefresh)
  }
}

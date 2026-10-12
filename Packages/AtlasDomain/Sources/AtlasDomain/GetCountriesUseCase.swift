import Foundation

public struct GetCountriesUseCase: Sendable {
  private let repository: any CountriesRepository

  public init(repository: any CountriesRepository) {
    self.repository = repository
  }

  public func callAsFunction(matching term: String, forceRefresh: Bool) async throws -> [CountrySummary] {
    // The API sorts by code.
    try await repository.countries(matching: term, forceRefresh: forceRefresh)
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }
}

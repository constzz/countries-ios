import CountriesDomain
import SwiftUI

public extension EnvironmentValues {
  /// The repository screens build their view models with. The app injects the real one.
  @Entry var countriesRepository: any CountriesRepository = UnavailableCountriesRepository()
}

/// Stands in until the app injects a repository: every request fails.
struct UnavailableCountriesRepository: CountriesRepository {
  func countries(matching _: String, forceRefresh _: Bool) async throws -> [CountrySummary] {
    throw CountriesError.unknown
  }
}

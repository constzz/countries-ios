import CountriesData
import CountriesDomain
import Foundation

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  /// `nil` while the app hosts tests, so no test run touches the network; screens then fall back
  /// to a repository whose requests fail.
  let countriesRepository: (any CountriesRepository)?

  init(environment: [String: String] = ProcessInfo.processInfo.environment) {
    let isHostingTests = environment["XCTestConfigurationFilePath"] != nil
    countriesRepository = isHostingTests ? nil : makeCountriesRepository(
      endpoint: Self.endpoint,
      requestTimeout: Self.requestTimeout
    )
  }

  // swiftlint:disable:next force_unwrapping
  private static let endpoint = URL(string: "https://countries.trevorblades.com/graphql")!
  /// How long a request may wait for data before it fails, instead of URLSession's 60 s.
  private static let requestTimeout: TimeInterval = 15
}

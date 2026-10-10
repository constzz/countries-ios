import CountriesData
import CountriesDomain
import Foundation

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  /// `nil` while the app hosts tests: the app then shows no screen, so no test run touches the
  /// network.
  let countriesRepository: (any CountriesRepository)?

  init(environment: [String: String] = ProcessInfo.processInfo.environment, bundle: Bundle = .main) {
    let isHostingTests = environment["XCTestConfigurationFilePath"] != nil
    countriesRepository = isHostingTests ? nil : makeCountriesRepository(endpoint: Self.endpoint(in: bundle))
  }

  /// The API endpoint, set by `COUNTRIES_API_URL` in `Config/Shared.xcconfig`.
  private static func endpoint(in bundle: Bundle) -> URL {
    guard let value = bundle.object(forInfoDictionaryKey: "CountriesAPIURL") as? String,
          let url = URL(string: value), url.scheme != nil
    else {
      preconditionFailure("CountriesAPIURL is missing from Info.plist. Set COUNTRIES_API_URL in Config/Shared.xcconfig.")
    }
    return url
  }
}

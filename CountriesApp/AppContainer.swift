import CountriesData
import CountriesDomain
import Foundation

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  let countriesRepository: any CountriesRepository

  init(bundle: Bundle = .main) {
    countriesRepository = makeCountriesRepository(endpoint: Self.endpoint(in: bundle))
  }

  /// The API endpoint, set by `COUNTRIES_API_URL` in `Config/Shared.xcconfig`.
  private static func endpoint(in bundle: Bundle) -> URL {
    let value = bundle.object(forInfoDictionaryKey: "CountriesAPIURL") as? String
    guard let url = value.flatMap(URL.init(string:)), url.scheme != nil else {
      preconditionFailure("No valid CountriesAPIURL in Info.plist: set COUNTRIES_API_URL in Config/Shared.xcconfig.")
    }
    return url
  }
}

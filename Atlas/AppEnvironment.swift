import Foundation

/// The settings a build configuration passes to the app through its Info.plist.
struct AppEnvironment {
  /// The Countries GraphQL API, set by `COUNTRIES_API_URL` in `Config/Shared.xcconfig`.
  let countriesAPIURL: URL
}

extension AppEnvironment {
  /// Reads the settings from `bundle`'s Info.plist. A missing or invalid value stops the app.
  init(bundle: Bundle) {
    let value = bundle.object(forInfoDictionaryKey: "CountriesAPIURL") as? String
    guard let url = value.flatMap(URL.init(string:)), url.scheme != nil else {
      preconditionFailure("No valid CountriesAPIURL in Info.plist: set COUNTRIES_API_URL in Config/Shared.xcconfig.")
    }
    countriesAPIURL = url
  }
}

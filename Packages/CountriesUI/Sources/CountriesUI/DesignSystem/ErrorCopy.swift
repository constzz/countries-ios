import CountriesDomain
import Foundation

/// What an error state says. The domain error carries no text; this is where it gets its copy.
struct ErrorCopy: Equatable {
  /// What failed to load, which the generic failure's title names.
  enum Subject {
    case countries
    case country
  }

  let title: String
  let message: String
  let systemImage: String
  /// Whether Try Again could help.
  var canRetry = true

  init(_ error: CountriesError, subject: Subject) {
    switch error {
    case .offline:
      title = String(
        localized: "You’re Offline",
        bundle: .module,
        comment: "Title of the error state when the device has no internet connection."
      )
      message = String(
        localized: "Connect to the internet and try again.",
        bundle: .module,
        comment: "Message of the error state when the device has no internet connection."
      )
      systemImage = "wifi.slash"
    case .notFound:
      title = String(
        localized: "Country Not Found",
        bundle: .module,
        comment: "Title of the state shown when the selected country no longer exists."
      )
      message = String(
        localized: "This country isn’t available. Choose another one.",
        bundle: .module,
        comment: "Message of the state shown when the selected country no longer exists."
      )
      systemImage = "mappin.slash"
      // The country won't start existing, so repeating the request can't help.
      canRetry = false
    case .network, .server, .decoding, .unknown:
      title = subject.failureTitle
      message = String(
        localized: "Something went wrong. Try again in a moment.",
        bundle: .module,
        comment: "Message of the error state when the countries or a country failed to load, unless offline."
      )
      systemImage = "exclamationmark.triangle"
    }
  }
}

private extension ErrorCopy.Subject {
  /// The title of a failure other than being offline.
  var failureTitle: String {
    switch self {
    case .countries:
      String(
        localized: "Couldn’t Load Countries",
        bundle: .module,
        comment: "Title of the error state when the country list failed to load for any reason but being offline."
      )
    case .country:
      String(
        localized: "Couldn’t Load Country",
        bundle: .module,
        comment: "Title of the error state when a country's details failed to load for any reason but being offline."
      )
    }
  }
}

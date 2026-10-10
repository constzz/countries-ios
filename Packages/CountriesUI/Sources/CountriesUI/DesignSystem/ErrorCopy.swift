import CountriesDomain
import Foundation

/// What an error state says. The domain error carries no text; this is where it gets its copy.
struct ErrorCopy: Equatable {
  let title: String
  let message: String
  let systemImage: String

  init(_ error: CountriesError) {
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
    case .network, .server, .notFound, .decoding, .unknown:
      title = String(
        localized: "Couldn’t Load Countries",
        bundle: .module,
        comment: "Title of the error state when the country list failed to load for any reason but being offline."
      )
      message = String(
        localized: "Something went wrong. Try again in a moment.",
        bundle: .module,
        comment: "Message of the error state when the country list failed to load for any reason but being offline."
      )
      systemImage = "exclamationmark.triangle"
    }
  }
}

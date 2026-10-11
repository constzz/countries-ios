import AtlasDomain
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
      title = String(localized: .errorOfflineTitle)
      message = String(localized: .errorOfflineMessage)
      systemImage = "wifi.slash"
    // Only a single country can be missing. The list never gets `.notFound`; if it did, its
    // generic failure fits.
    case .notFound where subject == .country:
      title = String(localized: .countryDetailNotFoundTitle)
      message = String(localized: .countryDetailNotFoundMessage)
      systemImage = "mappin.slash"
      // The country won't start existing, so repeating the request can't help.
      canRetry = false
    case .network, .server, .decoding, .notFound, .unknown:
      title = subject.failureTitle
      message = String(localized: .errorGenericMessage)
      systemImage = "exclamationmark.triangle"
    }
  }
}

private extension ErrorCopy.Subject {
  /// The title of a failure other than being offline.
  var failureTitle: String {
    switch self {
    case .countries:
      String(localized: .countryListErrorTitle)
    case .country:
      String(localized: .countryDetailErrorTitle)
    }
  }
}

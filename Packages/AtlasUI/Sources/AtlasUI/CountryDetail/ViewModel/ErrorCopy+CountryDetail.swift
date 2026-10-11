import Foundation

extension ErrorCopy {
  static let countryDetailFailure = failure(title: String(localized: .countryDetailErrorTitle))

  /// The country won't start existing, so repeating the request can't help.
  static let countryNotFound = ErrorCopy(
    title: String(localized: .countryDetailNotFoundTitle),
    message: String(localized: .countryDetailNotFoundMessage),
    systemImage: "mappin.slash",
    canRetry: false
  )
}

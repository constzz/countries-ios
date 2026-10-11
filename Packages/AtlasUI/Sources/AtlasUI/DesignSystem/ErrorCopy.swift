import Foundation

struct ErrorCopy: Equatable {
  let title: String
  let message: String
  let systemImage: String
  var canRetry = true

  static let offline = ErrorCopy(
    title: String(localized: .errorOfflineTitle),
    message: String(localized: .errorOfflineMessage),
    systemImage: "wifi.slash"
  )

  static func failure(title: String) -> ErrorCopy {
    ErrorCopy(
      title: title,
      message: String(localized: .errorGenericMessage),
      systemImage: "exclamationmark.triangle"
    )
  }
}

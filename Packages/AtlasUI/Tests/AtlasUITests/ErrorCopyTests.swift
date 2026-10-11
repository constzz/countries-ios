import AtlasDomain
import Foundation
import Testing
@testable import AtlasUI

@Suite("Error copy")
struct ErrorCopyTests {
  @Test("AC-1.6 offline has its own message", arguments: [ErrorCopy.Subject.countries, .country])
  func offlineHasItsOwnMessage(subject: ErrorCopy.Subject) {
    let offline = ErrorCopy(.offline, subject: subject)

    #expect(offline.title == String(localized: .errorOfflineTitle))
    #expect(offline.message == String(localized: .errorOfflineMessage))
    #expect(offline.systemImage == "wifi.slash")
    #expect(offline.canRetry)
    #expect(offline != ErrorCopy(.network, subject: subject))
  }

  /// The list never gets `.notFound`; if it did, its generic failure would fit.
  @Test(
    "AC-1.10 error copy comes from the catalog",
    arguments: [RequestError.network, .server, .decoding, .notFound, .unknown]
  )
  func errorCopyComesFromTheCatalog(error: RequestError) {
    let copy = ErrorCopy(error, subject: .countries)

    #expect(copy.title == String(localized: .countryListErrorTitle))
    #expect(copy.message == String(localized: .errorGenericMessage))
    #expect(copy.systemImage == "exclamationmark.triangle")
    #expect(copy.canRetry)
  }

  @Test("AC-2.4 the detail's error names a country", arguments: [RequestError.network, .server, .decoding, .unknown])
  func detailErrorNamesACountry(error: RequestError) {
    let copy = ErrorCopy(error, subject: .country)

    #expect(copy.title == String(localized: .countryDetailErrorTitle))
    #expect(copy.message == String(localized: .errorGenericMessage))
    #expect(copy.systemImage == "exclamationmark.triangle")
    #expect(copy.canRetry)
  }

  @Test("AC-2.5 not found has its own copy and no retry")
  func notFoundHasItsOwnCopyAndNoRetry() {
    let copy = ErrorCopy(.notFound, subject: .country)

    #expect(copy.title == String(localized: .countryDetailNotFoundTitle))
    #expect(copy.message == String(localized: .countryDetailNotFoundMessage))
    #expect(copy.systemImage == "mappin.slash")
    #expect(!copy.canRetry)
  }
}

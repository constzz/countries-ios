import CountriesDomain
import Foundation
import Testing
@testable import CountriesUI

@Suite("Error copy")
struct ErrorCopyTests {
  @Test("AC-1.6 offline has its own message", arguments: [ErrorCopy.Subject.countries, .country])
  func offlineHasItsOwnMessage(subject: ErrorCopy.Subject) {
    let offline = ErrorCopy(.offline, subject: subject)

    #expect(offline.title == String(localized: "You’re Offline", bundle: .module))
    #expect(offline.message == String(localized: "Connect to the internet and try again.", bundle: .module))
    #expect(offline.systemImage == "wifi.slash")
    #expect(offline.canRetry)
    #expect(offline != ErrorCopy(.network, subject: subject))
  }

  /// The list never gets `.notFound`; if it did, its generic failure would fit.
  @Test(
    "AC-1.10 error copy comes from the catalog",
    arguments: [CountriesError.network, .server, .decoding, .notFound, .unknown]
  )
  func errorCopyComesFromTheCatalog(error: CountriesError) {
    let copy = ErrorCopy(error, subject: .countries)

    #expect(copy.title == String(localized: "Couldn’t Load Countries", bundle: .module))
    #expect(copy.message == String(localized: "Something went wrong. Try again in a moment.", bundle: .module))
    #expect(copy.systemImage == "exclamationmark.triangle")
    #expect(copy.canRetry)
  }

  @Test("AC-2.4 the detail's error names a country", arguments: [CountriesError.network, .server, .decoding, .unknown])
  func detailErrorNamesACountry(error: CountriesError) {
    let copy = ErrorCopy(error, subject: .country)

    #expect(copy.title == String(localized: "Couldn’t Load Country", bundle: .module))
    #expect(copy.message == String(localized: "Something went wrong. Try again in a moment.", bundle: .module))
    #expect(copy.systemImage == "exclamationmark.triangle")
    #expect(copy.canRetry)
  }

  @Test("AC-2.5 not found has its own copy and no retry")
  func notFoundHasItsOwnCopyAndNoRetry() {
    let copy = ErrorCopy(.notFound, subject: .country)

    #expect(copy.title == String(localized: "Country Not Found", bundle: .module))
    #expect(copy.message == String(localized: "This country isn’t available. Choose another one.", bundle: .module))
    #expect(copy.systemImage == "mappin.slash")
    #expect(!copy.canRetry)
  }
}

import CountriesDomain
import Foundation
import Testing
@testable import CountriesUI

@Suite("Error copy")
struct ErrorCopyTests {
  @Test("AC-1.6 offline has its own message")
  func offlineHasItsOwnMessage() {
    let offline = ErrorCopy(.offline)

    #expect(offline.title == String(localized: "You’re Offline", bundle: .module))
    #expect(offline.message == String(localized: "Connect to the internet and try again.", bundle: .module))
    #expect(offline.systemImage == "wifi.slash")
    #expect(offline != ErrorCopy(.network))
  }

  @Test(
    "AC-1.10 error copy comes from the catalog",
    arguments: [CountriesError.network, .server, .decoding, .notFound, .unknown]
  )
  func errorCopyComesFromTheCatalog(error: CountriesError) {
    let copy = ErrorCopy(error)

    #expect(copy.title == String(localized: "Couldn’t Load Countries", bundle: .module))
    #expect(copy.message == String(localized: "Something went wrong. Try again in a moment.", bundle: .module))
    #expect(copy.systemImage == "exclamationmark.triangle")
  }
}

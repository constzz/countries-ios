import AtlasDomain
import Foundation
import Testing
@testable import AtlasUI

@Suite("Error copy", .testTime)
@MainActor
struct ErrorCopyTests {
  @Test("AC-1.6 offline has its own message")
  func offlineHasItsOwnMessage() {
    #expect(ErrorCopy.offline == ErrorCopy(
      title: String(localized: .errorOfflineTitle),
      message: String(localized: .errorOfflineMessage),
      systemImage: "wifi.slash"
    ))
  }

  @Test("AC-1.10 a failure is titled after what failed, with the shared message")
  func failureIsTitledAfterWhatFailed() {
    #expect(ErrorCopy.failure(title: "Title") == ErrorCopy(
      title: "Title",
      message: String(localized: .errorGenericMessage),
      systemImage: "exclamationmark.triangle"
    ))
    #expect(ErrorCopy.countryListFailure.title == String(localized: .countryListErrorTitle))
    #expect(ErrorCopy.countryDetailFailure.title == String(localized: .countryDetailErrorTitle))
  }

  @Test(
    "AC-1.6 the list shows offline, and its failure for anything else",
    arguments: [RequestError.offline, .network, .server, .notFound, .decoding, .unknown]
  )
  func listCopy(error: RequestError) async {
    let viewModel = CountryListViewModel(repository: MockCountriesRepository(result: .failure(error)))

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .failed(error == .offline ? .offline : .countryListFailure))
  }

  @Test(
    "AC-2.4 the detail's failure names a country",
    arguments: [RequestError.network, .server, .decoding, .unknown]
  )
  func detailFailureNamesACountry(error: RequestError) async {
    #expect(await detailContent(after: error) == .failed(.countryDetailFailure))
  }

  @Test("AC-2.5 not found has its own copy and no retry")
  func notFoundHasItsOwnCopyAndNoRetry() async {
    #expect(await detailContent(after: .notFound) == .failed(ErrorCopy(
      title: String(localized: .countryDetailNotFoundTitle),
      message: String(localized: .countryDetailNotFoundMessage),
      systemImage: "mappin.slash",
      canRetry: false
    )))
  }

  private func detailContent(after error: RequestError) async -> CountryDetailState.Content {
    let viewModel = CountryDetailViewModel(
      countryCode: "CH",
      repository: MockCountriesRepository(detailResult: .failure(error))
    )
    await viewModel.send(.appeared).value
    return viewModel.state.content
  }
}

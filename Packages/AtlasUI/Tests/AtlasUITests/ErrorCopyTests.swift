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
  }

  @Test(
    "AC-1.6 the list shows offline, and its failure for anything else",
    arguments: [RequestError.offline, .network, .server, .notFound, .decoding, .unknown]
  )
  func listCopy(error: RequestError) async {
    let sut = makeSUT(result: .failure(error))

    await sut.send(.appeared).value

    let failure = ErrorCopy.failure(title: String(localized: .countryListErrorTitle))
    #expect(sut.state.content == .failed(error == .offline ? .offline : failure))
  }

  @Test(
    "AC-2.4 the detail's failure names a country",
    arguments: [RequestError.network, .server, .decoding, .unknown]
  )
  func detailFailureNamesACountry(error: RequestError) async {
    #expect(await detailContent(after: error) == .failed(.failure(title: String(localized: .countryDetailErrorTitle))))
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

  private func makeSUT(result: Result<[CountrySummary], RequestError>) -> CountryListViewModel {
    CountryListViewModel(getCountries: GetCountriesUseCase(repository: MockCountriesRepository(result: result)))
  }

  private func makeSUT(detailResult: Result<CountryDetails, RequestError>) -> CountryDetailViewModel {
    CountryDetailViewModel(
      countryCode: "CH",
      getCountryDetails: GetCountryDetailsUseCase(repository: MockCountriesRepository(detailResult: detailResult))
    )
  }

  private func detailContent(after error: RequestError) async -> CountryDetailState.Content {
    let sut = makeSUT(detailResult: .failure(error))
    await sut.send(.appeared).value
    return sut.state.content
  }
}

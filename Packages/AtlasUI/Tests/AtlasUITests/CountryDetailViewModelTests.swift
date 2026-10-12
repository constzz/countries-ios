import AtlasDomain
import AtlasMVITesting
import Foundation
import Testing
@testable import AtlasUI

/// Every action, sent to the view model with a test repository: the state it leaves and the
/// requests it makes. The test plan runs in US English, so the text is checked against English.
@Suite("CountryDetailViewModel")
@MainActor
struct CountryDetailViewModelTests {
  private let details = CountryDetails.switzerland
  private let values = CountryDetailValues(
    name: "Switzerland",
    flag: "🇨🇭",
    capital: "Bern",
    currencies: "CHE, CHF, and CHW",
    languages: "German, French, and Italian",
    continent: "Europe"
  )

  // MARK: Loading

  @Test("AC-2.4 appearing shows loading, then the details")
  func appearingShowsLoadingThenTheDetails() async {
    let (sut, repository) = makeSUT(countryCode: "CH")

    let load = sut.send(.appeared)

    #expect(sut.state.content == .loading)
    let isRequested = await eventually { await repository.requestedCodes == ["CH"] }
    #expect(isRequested)
    await repository.respond(to: 0, with: .success(details))
    await load.value
    #expect(sut.state.content == .loaded(values))
  }

  @Test("AC-2.4 appearing again loads nothing")
  func appearingAgainLoadsNothing() async {
    let (sut, repository) = makeSUT(countryCode: "CH", detailResult: .success(details))
    await sut.send(.appeared).value

    await sut.send(.appeared).value

    #expect(sut.state.content == .loaded(values))
    #expect(await repository.requestedCodes == ["CH"])
  }

  @Test("AC-2.4 a failure shows the error")
  func failureShowsTheError() async {
    let (sut, _) = makeSUT(countryCode: "CH", detailResult: .failure(.offline))

    await sut.send(.appeared).value

    #expect(sut.state.content == .failed(.offline))
  }

  @Test("AC-2.4 retry repeats the request")
  func retryRepeatsTheRequest() async {
    let (sut, repository) = makeSUT(countryCode: "CH", detailResult: .failure(.network))
    await sut.send(.appeared).value
    await repository.setDetailResult(.success(details))

    let retry = sut.send(.retryTapped)

    #expect(sut.state.content == .loading)
    await retry.value
    #expect(sut.state.content == .loaded(values))
    #expect(await repository.requestedCodes == ["CH", "CH"])
  }

  @Test("AC-2.5 an unknown code shows not found")
  func unknownCodeShowsNotFound() async {
    let (sut, _) = makeSUT(countryCode: "XX", detailResult: .failure(.notFound))

    await sut.send(.appeared).value

    guard case let .failed(copy) = sut.state.content else {
      Issue.record("Expected not found, got \(sut.state.content)")
      return
    }
    #expect(copy.title == String(localized: .countryDetailNotFoundTitle))
  }

  // MARK: Title

  @Test("AC-2.2 the title shows once the header's name is under the bar")
  func titleShowsOnceTheHeaderIsUnderTheBar() async {
    let (sut, _) = makeSUT(countryCode: "CH", detailResult: .success(details))
    await sut.send(.appeared).value
    #expect(!sut.state.isHeaderUnderBar)

    sut.send(.headerScrolled(underBar: true))

    #expect(sut.state.isHeaderUnderBar)
  }

  @Test("AC-2.2 the title hides when the header's name scrolls back")
  func titleHidesWhenTheHeaderScrollsBack() async {
    let (sut, _) = makeSUT(countryCode: "CH", detailResult: .success(details))
    await sut.send(.appeared).value
    sut.send(.headerScrolled(underBar: true))

    sut.send(.headerScrolled(underBar: false))

    #expect(!sut.state.isHeaderUnderBar)
  }

  // MARK: Cancelling

  @Test("AC-2.10 disappearing cancels the request and shows no error")
  func disappearingCancelsTheRequest() async {
    let (sut, repository) = makeSUT(countryCode: "CH")
    let load = sut.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }

    sut.send(.disappeared)

    #expect(sut.state.content == .idle)
    let isCancelled = await eventually { await repository.cancelledCount == 1 }
    #expect(isCancelled)
    await load.value
    #expect(sut.state.content == .idle)
  }

  @Test("AC-2.10 appearing after disappearing loads again")
  func appearingAfterDisappearingLoadsAgain() async {
    let (sut, repository) = makeSUT(countryCode: "CH")
    sut.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }
    sut.send(.disappeared)

    let reload = sut.send(.appeared)

    #expect(sut.state.content == .loading)
    let isRequested = await eventually { await repository.requestedCodes == ["CH", "CH"] }
    #expect(isRequested)
    await repository.respond(to: 1, with: .success(details))
    await reload.value
    #expect(sut.state.content == .loaded(values))
  }

  @Test("AC-2.10 a stale response is ignored")
  func staleResponseIsIgnored() async {
    let (sut, repository) = makeSUT(countryCode: "CH", honorsCancellation: false)
    let staleLoad = sut.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }
    sut.send(.disappeared)
    let reload = sut.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH", "CH"] }

    await repository.respond(to: 0, with: .failure(.network))
    await staleLoad.value

    #expect(sut.state.content == .loading)
    await repository.respond(to: 1, with: .success(details))
    await reload.value
    #expect(sut.state.content == .loaded(values))
  }

  // MARK: Text

  @Test("AC-2.2 every row shows its value")
  func everyRowShowsItsValue() async {
    #expect(await loadedValues(.southGeorgia) == CountryDetailValues(
      name: "South Georgia and the South Sandwich Islands",
      flag: "🇬🇸",
      capital: "King Edward Point",
      currencies: "GBP",
      languages: "English",
      continent: "Antarctica"
    ))
  }

  @Test("AC-2.3 missing values read None")
  func missingValuesReadNone() async {
    let values = await loadedValues(.antarctica)

    let none = String(localized: .countryDetailNone)
    #expect(values?.capital == none)
    #expect(values?.currencies == none)
    #expect(values?.languages == none)
    #expect(values?.continent == "Antarctica")
  }

  @Test("AC-2.7 currencies and languages use the view model's locale's list format")
  func listsUseTheLocalesListFormat() async {
    let english = await loadedValues(.switzerland)
    let german = await loadedValues(.switzerland, locale: Locale(identifier: "de_DE"))

    #expect(english?.currencies == "CHE, CHF, and CHW")
    #expect(english?.languages == "German, French, and Italian")
    #expect(german?.currencies == "CHE, CHF und CHW")
  }

  // MARK: Helpers

  /// A view model whose repository answers every request with `detailResult`.
  private func makeSUT(
    countryCode: String,
    detailResult: Result<CountryDetails, RequestError>,
    locale: Locale = .autoupdatingCurrent
  ) -> (sut: CountryDetailViewModel, repository: MockCountriesRepository) {
    let repository = MockCountriesRepository(detailResult: detailResult)
    let sut = CountryDetailViewModel(
      countryCode: countryCode,
      getCountryDetailsUseCase: GetCountryDetailsUseCase(repository: repository),
      locale: locale
    )
    return (sut, repository)
  }

  /// A view model whose repository holds each request until the test answers it.
  private func makeSUT(
    countryCode: String,
    honorsCancellation: Bool = true
  ) -> (sut: CountryDetailViewModel, repository: SuspendingDetailsRepository) {
    let repository = SuspendingDetailsRepository(honorsCancellation: honorsCancellation)
    let sut = CountryDetailViewModel(
      countryCode: countryCode,
      getCountryDetailsUseCase: GetCountryDetailsUseCase(repository: repository)
    )
    return (sut, repository)
  }

  /// What the detail shows once `details` loads, or `nil` if it didn't load.
  private func loadedValues(
    _ details: CountryDetails,
    locale: Locale = .autoupdatingCurrent
  ) async -> CountryDetailValues? {
    let (sut, _) = makeSUT(countryCode: details.id, detailResult: .success(details), locale: locale)
    await sut.send(.appeared).value
    guard case let .loaded(values) = sut.state.content else {
      return nil
    }
    return values
  }
}

import AtlasDomain
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
    let repository = SuspendingDetailsRepository()
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)

    let load = viewModel.send(.appeared)

    #expect(viewModel.state.content == .loading)
    let isRequested = await eventually { await repository.requestedCodes == ["CH"] }
    #expect(isRequested)
    await repository.respond(to: 0, with: .success(details))
    await load.value
    #expect(viewModel.state.content == .loaded(values))
  }

  @Test("AC-2.4 appearing again loads nothing")
  func appearingAgainLoadsNothing() async {
    let repository = MockCountriesRepository(detailResult: .success(details))
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    await viewModel.send(.appeared).value

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .loaded(values))
    #expect(await repository.requestedCodes == ["CH"])
  }

  @Test("AC-2.4 a failure shows the error")
  func failureShowsTheError() async {
    let viewModel = CountryDetailViewModel(
      code: "CH",
      repository: MockCountriesRepository(detailResult: .failure(.offline))
    )

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .failed(.offline))
  }

  @Test("AC-2.4 retry repeats the request")
  func retryRepeatsTheRequest() async {
    let repository = MockCountriesRepository(detailResult: .failure(.network))
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    await viewModel.send(.appeared).value
    await repository.setDetailResult(.success(details))

    let retry = viewModel.send(.retryTapped)

    #expect(viewModel.state.content == .loading)
    await retry.value
    #expect(viewModel.state.content == .loaded(values))
    #expect(await repository.requestedCodes == ["CH", "CH"])
  }

  @Test("AC-2.5 an unknown code shows not found")
  func unknownCodeShowsNotFound() async {
    let viewModel = CountryDetailViewModel(
      code: "XX",
      repository: MockCountriesRepository(detailResult: .failure(.notFound))
    )

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .failed(.notFound))
  }

  // MARK: Title

  @Test("AC-2.2 the title shows once the header's name is under the bar")
  func titleShowsOnceTheHeaderIsUnderTheBar() async {
    let viewModel = CountryDetailViewModel(
      code: "CH",
      repository: MockCountriesRepository(detailResult: .success(details))
    )
    await viewModel.send(.appeared).value
    #expect(!viewModel.state.isHeaderUnderBar)

    viewModel.send(.headerScrolled(underBar: true))

    #expect(viewModel.state.isHeaderUnderBar)
  }

  @Test("AC-2.2 the title hides when the header's name scrolls back")
  func titleHidesWhenTheHeaderScrollsBack() async {
    let viewModel = CountryDetailViewModel(
      code: "CH",
      repository: MockCountriesRepository(detailResult: .success(details))
    )
    await viewModel.send(.appeared).value
    viewModel.send(.headerScrolled(underBar: true))

    viewModel.send(.headerScrolled(underBar: false))

    #expect(!viewModel.state.isHeaderUnderBar)
  }

  // MARK: Cancelling

  @Test("AC-2.10 disappearing cancels the request and shows no error")
  func disappearingCancelsTheRequest() async {
    let repository = SuspendingDetailsRepository()
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    let load = viewModel.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }

    viewModel.send(.disappeared)

    #expect(viewModel.state.content == .idle)
    let isCancelled = await eventually { await repository.cancelledCount == 1 }
    #expect(isCancelled)
    await load.value
    #expect(viewModel.state.content == .idle)
  }

  @Test("AC-2.10 appearing after disappearing loads again")
  func appearingAfterDisappearingLoadsAgain() async {
    let repository = SuspendingDetailsRepository()
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    viewModel.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }
    viewModel.send(.disappeared)

    let reload = viewModel.send(.appeared)

    #expect(viewModel.state.content == .loading)
    let isRequested = await eventually { await repository.requestedCodes == ["CH", "CH"] }
    #expect(isRequested)
    await repository.respond(to: 1, with: .success(details))
    await reload.value
    #expect(viewModel.state.content == .loaded(values))
  }

  @Test("AC-2.10 a stale response is ignored")
  func staleResponseIsIgnored() async {
    let repository = SuspendingDetailsRepository(honorsCancellation: false)
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    let staleLoad = viewModel.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH"] }
    viewModel.send(.disappeared)
    let reload = viewModel.send(.appeared)
    _ = await eventually { await repository.requestedCodes == ["CH", "CH"] }

    await repository.respond(to: 0, with: .failure(.network))
    await staleLoad.value

    #expect(viewModel.state.content == .loading)
    await repository.respond(to: 1, with: .success(details))
    await reload.value
    #expect(viewModel.state.content == .loaded(values))
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

  /// What the detail shows once `details` loads, or `nil` if it didn't load.
  private func loadedValues(
    _ details: CountryDetails,
    locale: Locale = .autoupdatingCurrent
  ) async -> CountryDetailValues? {
    let viewModel = CountryDetailViewModel(
      code: details.id,
      repository: MockCountriesRepository(detailResult: .success(details)),
      locale: locale
    )
    await viewModel.send(.appeared).value
    guard case let .loaded(values) = viewModel.state.content else {
      return nil
    }
    return values
  }
}

import CountriesDomain
import Testing
@testable import CountriesUI

/// Every action, sent to the view model with a test repository: the state it leaves and the
/// requests it makes.
@Suite("CountryDetailViewModel")
@MainActor
struct CountryDetailViewModelTests {
  private let details = CountryDetails.switzerland

  // MARK: Loading

  @Test("AC-2.4 appearing shows loading, then the details")
  func appearingShowsLoadingThenTheDetails() async {
    let repository = SuspendingDetailsRepository()
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)

    let load = viewModel.send(.appeared)

    #expect(viewModel.state.content == .loading)
    let isRequested = await eventually { await repository.requestedCodes == ["CH"] }
    #expect(isRequested)
    await repository.respond(with: .success(details))
    await load.value
    #expect(viewModel.state.content == .loaded(details))
  }

  @Test("AC-2.4 appearing again loads nothing")
  func appearingAgainLoadsNothing() async {
    let repository = MockCountriesRepository(detailResult: .success(details))
    let viewModel = CountryDetailViewModel(code: "CH", repository: repository)
    await viewModel.send(.appeared).value

    await viewModel.send(.appeared).value

    #expect(viewModel.state.content == .loaded(details))
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
    #expect(viewModel.state.content == .loaded(details))
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
    #expect(!viewModel.state.showsTitle)

    viewModel.send(.headerScrolled(underBar: true))

    #expect(viewModel.state.showsTitle)
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

    #expect(!viewModel.state.showsTitle)
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
    await repository.respond(with: .success(details))
    await reload.value
    #expect(viewModel.state.content == .loaded(details))
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

    await repository.respond(with: .failure(.network))
    await staleLoad.value

    #expect(viewModel.state.content == .loading)
    await repository.respond(with: .success(details))
    await reload.value
    #expect(viewModel.state.content == .loaded(details))
  }
}

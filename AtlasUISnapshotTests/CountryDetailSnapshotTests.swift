import AtlasDomain
import SwiftUI
import Testing
@testable import AtlasUI

/// Each detail state beside the list, with the country's row selected, fed a fixed state: nothing
/// loads and nothing waits. On compact width the detail shows pushed.
@Suite(
  "Country detail snapshots",
  .enabled(if: SnapshotEnvironment.isEnabled, SnapshotEnvironment.notReferenceReason)
)
@MainActor
struct CountryDetailSnapshotTests {
  @Test("AC-2.4 AC-2.6 loading")
  func loading() async {
    let sut = makeSUT(.loading)

    await assertSnapshots(of: sut, named: "COUNTRY_DETAIL_LOADING", everyDevice: false)
  }

  @Test("AC-2.2 AC-2.6 AC-2.7 loaded, with right-to-left")
  func loaded() async {
    let sut = makeSUT(.loaded(.bolivia))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_DETAIL_LOADED",
      rightToLeft: true
    )
  }

  @Test("AC-2.3 AC-2.6 missing values read None")
  func missingValues() async {
    let sut = makeSUT(.loaded(.antarctica))

    await assertSnapshots(of: sut, named: "COUNTRY_DETAIL_MISSING_VALUES")
  }

  @Test("AC-2.2 AC-2.6 the longest name wraps")
  func longName() async {
    let sut = makeSUT(.loaded(.southGeorgia))

    await assertSnapshots(of: sut, named: "COUNTRY_DETAIL_LONG_NAME")
  }

  @Test("AC-2.4 AC-2.6 error")
  func error() async {
    let sut = makeSUT(.failed(.failure(title: String(localized: .countryDetailErrorTitle))))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_DETAIL_ERROR",
      everyDevice: false
    )
  }

  @Test("AC-2.4 AC-2.6 offline")
  func offline() async {
    let sut = makeSUT(.failed(.offline))

    await assertSnapshots(of: sut, named: "COUNTRY_DETAIL_OFFLINE", everyDevice: false)
  }

  @Test("AC-2.5 AC-2.6 not found")
  func notFound() async {
    let sut = makeSUT(.failed(ErrorCopy(
      title: String(localized: .countryDetailNotFoundTitle),
      message: String(localized: .countryDetailNotFoundMessage),
      systemImage: "mappin.slash",
      canRetry: false
    )))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_DETAIL_NOT_FOUND",
      everyDevice: false
    )
  }

  /// Bolivia's row is selected in every state, so the iPad images show the highlight.
  private func makeSUT(_ content: CountryDetailState.Content) -> some View {
    RootSplitView {
      CountryListContent(
        state: CountryListState(content: .loaded(CountrySummary.samples)),
        selection: .constant(CountryDetails.bolivia.id)
      ) { _ in Task {} }
    } detail: {
      CountryDetailContent(state: CountryDetailState(content: content)) { _ in Task {} }
    }
  }
}

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
    await assertSnapshots(of: countryDetail(.loading), named: "COUNTRY_DETAIL_LOADING", everyDevice: false)
  }

  @Test("AC-2.2 AC-2.6 AC-2.7 loaded, with right-to-left")
  func loaded() async {
    await assertSnapshots(
      of: countryDetail(.loaded(.bolivia)),
      named: "COUNTRY_DETAIL_LOADED",
      rightToLeft: true
    )
  }

  @Test("AC-2.3 AC-2.6 missing values read None")
  func missingValues() async {
    await assertSnapshots(of: countryDetail(.loaded(.antarctica)), named: "COUNTRY_DETAIL_MISSING_VALUES")
  }

  @Test("AC-2.2 AC-2.6 the longest name wraps")
  func longName() async {
    await assertSnapshots(of: countryDetail(.loaded(.southGeorgia)), named: "COUNTRY_DETAIL_LONG_NAME")
  }

  @Test("AC-2.4 AC-2.6 error")
  func error() async {
    await assertSnapshots(of: countryDetail(.failed(.network)), named: "COUNTRY_DETAIL_ERROR", everyDevice: false)
  }

  @Test("AC-2.4 AC-2.6 offline")
  func offline() async {
    await assertSnapshots(of: countryDetail(.failed(.offline)), named: "COUNTRY_DETAIL_OFFLINE", everyDevice: false)
  }

  @Test("AC-2.5 AC-2.6 not found")
  func notFound() async {
    await assertSnapshots(of: countryDetail(.failed(.notFound)), named: "COUNTRY_DETAIL_NOT_FOUND", everyDevice: false)
  }

  /// Bolivia's row is selected in every state, so the iPad images show the highlight.
  private func countryDetail(_ content: CountryDetailState.Content) -> some View {
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

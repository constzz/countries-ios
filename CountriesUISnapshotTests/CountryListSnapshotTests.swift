import CountriesDomain
import SwiftUI
import Testing
@testable import CountriesUI

/// Each list state in the split view, fed a fixed state: nothing loads and nothing waits.
@Suite(
  "Country list snapshots",
  .enabled(if: SnapshotEnvironment.isEnabled, SnapshotEnvironment.notReferenceReason)
)
@MainActor
struct CountryListSnapshotTests {
  @Test("AC-1.9 loading")
  func loading() async {
    await assertSnapshots(of: countryList(CountryListState(content: .loading)), named: "COUNTRY_LIST_LOADING")
  }

  @Test("AC-1.9 AC-1.10 loaded, with right-to-left")
  func loaded() async {
    await assertSnapshots(
      of: countryList(CountryListState(content: .loaded(CountrySummary.samples))),
      named: "COUNTRY_LIST_LOADED",
      rightToLeft: true
    )
  }

  @Test("AC-1.9 searching over the current rows")
  func searching() async {
    let state = CountryListState(
      content: .loaded(CountrySummary.samples),
      searchText: "a",
      query: "",
      isSearching: true
    )
    await assertSnapshots(of: countryList(state), named: "COUNTRY_LIST_SEARCHING")
  }

  @Test("AC-1.9 no match")
  func empty() async {
    let state = CountryListState(content: .empty(query: "zzz"), searchText: "zzz", query: "zzz")
    await assertSnapshots(of: countryList(state), named: "COUNTRY_LIST_EMPTY")
  }

  @Test("AC-1.9 error")
  func error() async {
    await assertSnapshots(of: countryList(CountryListState(content: .failed(.network))), named: "COUNTRY_LIST_ERROR")
  }

  @Test("AC-1.9 offline")
  func offline() async {
    await assertSnapshots(of: countryList(CountryListState(content: .failed(.offline))), named: "COUNTRY_LIST_OFFLINE")
  }

  private func countryList(_ state: CountryListState) -> some View {
    CountriesSplitView {
      CountryListContent(state: state, selection: .constant(nil)) { _ in Task {} }
    } detail: {
      SelectCountryPlaceholder()
    }
  }
}

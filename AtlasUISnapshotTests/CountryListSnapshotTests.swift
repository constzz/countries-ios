import AtlasDomain
import SwiftUI
import Testing
@testable import AtlasUI

/// Each list state in the split view, fed a fixed state: nothing loads and nothing waits.
@Suite(
  "Country list snapshots",
  .enabled(if: SnapshotEnvironment.isEnabled, SnapshotEnvironment.notReferenceReason)
)
@MainActor
struct CountryListSnapshotTests {
  @Test("AC-1.9 loading")
  func loading() async {
    let sut = makeSUT(CountryListState(content: .loading))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_LIST_LOADING",
      everyDevice: false
    )
  }

  @Test("AC-1.9 AC-1.10 loaded, with right-to-left")
  func loaded() async {
    let sut = makeSUT(CountryListState(content: .loaded(CountrySummary.samples)))

    await assertSnapshots(
      of: sut,
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
    let sut = makeSUT(state)

    await assertSnapshots(of: sut, named: "COUNTRY_LIST_SEARCHING")
  }

  @Test("AC-1.9 no match")
  func empty() async {
    let state = CountryListState(content: .empty(query: "zzz"), searchText: "zzz", query: "zzz")
    let sut = makeSUT(state)

    await assertSnapshots(of: sut, named: "COUNTRY_LIST_EMPTY", everyDevice: false)
  }

  @Test("AC-1.9 error")
  func error() async {
    let sut = makeSUT(CountryListState(content: .failed(.failure(title: String(localized: .countryListErrorTitle)))))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_LIST_ERROR",
      everyDevice: false
    )
  }

  @Test("AC-1.9 offline")
  func offline() async {
    let sut = makeSUT(CountryListState(content: .failed(.offline)))

    await assertSnapshots(
      of: sut,
      named: "COUNTRY_LIST_OFFLINE",
      everyDevice: false
    )
  }

  private func makeSUT(_ state: CountryListState) -> some View {
    RootSplitView {
      CountryListContent(state: state, selection: .constant(nil)) { _ in Task {} }
    } detail: {
      SelectCountryPlaceholder()
    }
  }
}

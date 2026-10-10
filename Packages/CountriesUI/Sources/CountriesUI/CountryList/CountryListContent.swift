import CountriesDomain
import SwiftUI

/// Draws a country list state and sends what the user does. It owns no state, so previews and
/// snapshots can show any state.
struct CountryListContent: View {
  let state: CountryListState
  let send: (CountryListAction) -> Task<Void, Never>

  var body: some View {
    List(rows) { country in
      CountryRow(country: country)
    }
    .navigationTitle(Text("Countries", bundle: .module, comment: "The app's name, shown as the root screen's title."))
    .searchable(
      text: searchText,
      prompt: Text(
        "Search by name",
        bundle: .module,
        comment: "Placeholder in the search field above the country list."
      )
    )
    .refreshable {
      await send(.refreshRequested).value
    }
    .loadState(
      phase,
      loadingLabel: Text(
        "Loading Countries…",
        bundle: .module,
        comment: "Label under the progress indicator while the country list loads."
      ),
      retry: { _ = send(.retryTapped) }
    )
    .inlineProgress(
      state.isSearching,
      label: Text("Searching…", bundle: .module, comment: "Shown above the country list while a search runs.")
    )
  }

  private var rows: [CountrySummary] {
    if case let .loaded(rows) = state.content {
      rows
    } else {
      []
    }
  }

  private var phase: LoadPhase? {
    switch state.content {
    case .idle, .loading:
      .loading
    case .loaded:
      nil
    case let .empty(query):
      .empty(query: query)
    case let .failed(error):
      .failed(error)
    }
  }

  private var searchText: Binding<String> {
    Binding(get: { state.searchText }, set: { _ = send(.searchTextChanged($0)) })
  }
}

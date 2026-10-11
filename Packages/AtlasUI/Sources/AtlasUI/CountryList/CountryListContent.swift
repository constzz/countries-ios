import AtlasDomain
import SwiftUI

/// Draws a country list state and sends what the user does. It owns no state, so previews and
/// snapshots can show any state.
struct CountryListContent: View {
  let state: CountryListState
  /// The selected country's code, owned by the root view.
  @Binding var selection: String?
  let send: (CountryListAction) -> Task<Void, Never>

  var body: some View {
    List(rows, selection: $selection) { country in
      NavigationLink(value: country.code) {
        CountryRow(country: country)
      }
    }
    .navigationTitle(Text(.countryListTitle))
    .searchable(text: searchText, prompt: Text(.countryListSearchPrompt))
    .refreshable {
      await send(.refreshRequested).value
    }
    .loadState(
      phase,
      subject: .countries,
      loadingLabel: Text(.countryListLoading),
      retry: { _ = send(.retryTapped) }
    )
    .inlineProgress(state.isSearching, label: Text(.countryListSearchInProgress))
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

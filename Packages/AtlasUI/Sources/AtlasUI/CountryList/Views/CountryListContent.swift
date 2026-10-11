import AtlasDomain
import SwiftUI

/// Draws a country list state and sends what the user does. It owns no state, so previews and
/// snapshots can show any state.
struct CountryListContent: View {
  let state: CountryListState
  /// The selected country's code.
  @Binding var selection: String?
  let send: (CountryListAction) -> Task<Void, Never>

  private var searchText: Binding<String> {
    Binding(get: { state.searchText }, set: { _ = send(.searchTextChanged($0)) })
  }

  var body: some View {
    List(state.rows, selection: $selection) { country in
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
      state.phase,
      loadingLabel: Text(.countryListLoading),
      retry: { _ = send(.retryTapped) }
    )
    .inlineProgress(state.isSearching, label: Text(.countryListSearchInProgress))
  }
}

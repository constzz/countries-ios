#if DEBUG
  import CountriesDomain
  import SwiftUI

  #Preview("Loading") {
    countryList(CountryListState(content: .loading))
  }

  #Preview("Loaded") {
    countryList(CountryListState(content: .loaded(CountrySummary.samples)))
  }

  #Preview("Searching") {
    countryList(CountryListState(content: .loaded(CountrySummary.samples), searchText: "a", isSearching: true))
  }

  #Preview("Empty") {
    countryList(CountryListState(content: .empty(query: "zzz"), searchText: "zzz", query: "zzz"))
  }

  #Preview("Error") {
    countryList(CountryListState(content: .failed(.network)))
  }

  #Preview("Offline") {
    countryList(CountryListState(content: .failed(.offline)))
  }

  #Preview("Loaded, dark") {
    countryList(CountryListState(content: .loaded(CountrySummary.samples)))
      .environment(\.colorScheme, .dark)
  }

  #Preview("Loaded, largest text") {
    countryList(CountryListState(content: .loaded(CountrySummary.samples)))
      .environment(\.dynamicTypeSize, .accessibility5)
  }

  @MainActor
  private func countryList(_ state: CountryListState) -> some View {
    CountriesSplitView {
      CountryListContent(state: state, selection: .constant(nil)) { _ in Task {} }
    } detail: {
      SelectCountryPlaceholder()
    }
  }
#endif

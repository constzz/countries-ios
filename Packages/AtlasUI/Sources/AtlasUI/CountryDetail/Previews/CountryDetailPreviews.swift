#if DEBUG
  import AtlasDomain
  import SwiftUI

  #Preview("Loading") {
    countryDetail(CountryDetailState(content: .loading))
  }

  #Preview("Loaded") {
    countryDetail(CountryDetailState(content: .loaded(.bolivia)))
  }

  #Preview("Missing values") {
    countryDetail(CountryDetailState(content: .loaded(.antarctica)))
  }

  #Preview("Long name") {
    countryDetail(CountryDetailState(content: .loaded(.southGeorgia)))
  }

  #Preview("Error") {
    countryDetail(CountryDetailState(content: .failed(.failure(title: String(localized: .countryDetailErrorTitle)))))
  }

  #Preview("Offline") {
    countryDetail(CountryDetailState(content: .failed(.offline)))
  }

  #Preview("Not found") {
    countryDetail(CountryDetailState(content: .failed(ErrorCopy(
      title: String(localized: .countryDetailNotFoundTitle),
      message: String(localized: .countryDetailNotFoundMessage),
      systemImage: "mappin.slash",
      canRetry: false
    ))))
  }

  #Preview("Loaded, dark") {
    countryDetail(CountryDetailState(content: .loaded(.bolivia)))
      .environment(\.colorScheme, .dark)
  }

  #Preview("Loaded, largest text") {
    countryDetail(CountryDetailState(content: .loaded(.bolivia)))
      .environment(\.dynamicTypeSize, .accessibility5)
  }

  /// The detail beside the list, with Bolivia selected; on compact width, pushed.
  @MainActor
  private func countryDetail(_ state: CountryDetailState) -> some View {
    RootSplitView {
      CountryListContent(
        state: CountryListState(content: .loaded(CountrySummary.samples)),
        selection: .constant(CountryDetails.bolivia.id)
      ) { _ in Task {} }
    } detail: {
      CountryDetailContent(state: state) { _ in Task {} }
    }
  }
#endif

import CountriesDomain
import SwiftUI

/// Draws a country detail state and sends what the user does. It owns no state, so previews and
/// snapshots can show any state.
struct CountryDetailContent: View {
  let state: CountryDetailState
  let send: (CountryDetailAction) -> Task<Void, Never>

  var body: some View {
    List {
      if case let .loaded(details) = state.content {
        rows(details)
      }
    }
    // An empty list draws a plain background, so loading and errors would sit on a different
    // color than the rows. The grouped background stays behind every state.
    .scrollContentBackground(.hidden)
    .background(.groupedBackground)
    .navigationTitle(Text(verbatim: title))
    .navigationBarTitleDisplayMode(.inline)
    .loadState(
      phase,
      subject: .country,
      loadingLabel: Text(
        "Loading Country…",
        bundle: .module,
        comment: "Label under the progress indicator while a country's details load."
      ),
      retry: { _ = send(.retryTapped) }
    )
  }

  private func rows(_ details: CountryDetails) -> some View {
    let values = CountryDetailValues(details)
    return Section {
      row(Text("Capital", bundle: .module, comment: "Label of the row with a country's capital city."), values.capital)
      row(
        Text("Currencies", bundle: .module, comment: "Label of the row with the currencies a country uses."),
        values.currencies
      )
      row(
        Text("Languages", bundle: .module, comment: "Label of the row with the languages spoken in a country."),
        values.languages
      )
      row(
        Text("Continent", bundle: .module, comment: "Label of the row with the continent a country is on."),
        values.continent
      )
    } header: {
      CountryDetailHeader(country: details.summary)
        .textCase(nil)
        .foregroundStyle(.primaryText)
        .padding(.bottom)
    }
  }

  private func row(_ label: Text, _ value: String) -> some View {
    LabeledContent {
      Text(verbatim: value)
    } label: {
      label
    }
  }

  /// The country's name once it's loaded. Nothing is shown before: the detail has only a code.
  private var title: String {
    if case let .loaded(details) = state.content {
      details.summary.name
    } else {
      ""
    }
  }

  private var phase: LoadPhase? {
    switch state.content {
    case .idle, .loading:
      .loading
    case .loaded:
      nil
    case let .failed(error):
      .failed(error)
    }
  }
}

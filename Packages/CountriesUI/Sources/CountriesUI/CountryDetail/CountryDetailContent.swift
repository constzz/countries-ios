import CountriesDomain
import SwiftUI

/// Draws a country detail state and sends what the user does. It owns no state, so previews and
/// snapshots can show any state.
struct CountryDetailContent: View {
  let state: CountryDetailState
  let send: (CountryDetailAction) -> Task<Void, Never>

  /// Where the navigation bar ends, in global coordinates. A list's frame starts there, under the
  /// bar, on every iOS version this app supports. Layout, not screen state, so it stays here.
  @State private var barBottom: CGFloat = 0
  /// The locale the rest of the screen's text uses, for "None" and the lists of values.
  @Environment(\.locale) private var locale

  var body: some View {
    List {
      if case let .loaded(details) = state.content {
        rows(details)
      }
    }
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.frame(in: .global).minY
    } action: { minY in
      barBottom = minY
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
    let values = CountryDetailValues(details, locale: locale)
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
      CountryDetailHeader(country: details.summary, barBottom: barBottom) { isUnderBar in
        _ = send(.headerScrolled(underBar: isUnderBar))
      }
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

  /// The country's name once the header's name is under the bar; until then the header shows it,
  /// and before the details load there's only a code.
  private var title: String {
    if case let .loaded(details) = state.content, state.showsTitle {
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

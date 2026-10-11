import AtlasDomain
import SwiftUI

/// Draws a country detail state and sends what the user does. It holds no screen state, so
/// previews and snapshots can show any state.
struct CountryDetailContent: View {
  let state: CountryDetailState
  let send: (CountryDetailAction) -> Task<Void, Never>

  /// Where the navigation bar ends, in global coordinates. A list's frame starts there, under the
  /// bar, on every iOS version this app supports. Layout, not screen state, so it stays here.
  @State private var barBottom: CGFloat = 0
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
    .background(Palette.groupedBackground)
    .navigationTitle(Text(verbatim: title))
    .navigationBarTitleDisplayMode(.inline)
    .loadState(
      phase,
      subject: .country,
      loadingLabel: Text(.countryDetailLoading),
      retry: { _ = send(.retryTapped) }
    )
  }

  private func rows(_ details: CountryDetails) -> some View {
    let values = CountryDetailValuesMapper.map(details, locale: locale)
    return Section {
      row(Text(.countryDetailCapital), values.capital)
      row(Text(.countryDetailCurrencies), values.currencies)
      row(Text(.countryDetailLanguages), values.languages)
      row(Text(.countryDetailContinent), values.continent)
    } header: {
      CountryDetailHeader(country: details.summary, barBottom: barBottom) { isUnderBar in
        _ = send(.headerScrolled(underBar: isUnderBar))
      }
      .textCase(nil)
      .foregroundStyle(Palette.primaryText)
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

  private var title: String {
    if case let .loaded(details) = state.content, state.isHeaderUnderBar {
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

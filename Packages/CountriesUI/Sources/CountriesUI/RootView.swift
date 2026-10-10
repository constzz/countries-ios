import CountriesDomain
import SwiftUI

/// The app's root screen. It owns the selection both columns share.
public struct RootView: View {
  @Environment(\.countriesRepository) private var repository
  /// The selected country's code. Each window keeps its own and restores it after relaunch.
  @SceneStorage("selectedCountryCode") private var selection: String?

  public init() {}

  public var body: some View {
    CountriesSplitView {
      CountryListView(repository: repository, selection: $selection)
    } detail: {
      if let selection {
        // A view, and so a view model, per country: nothing from the previous one can show.
        CountryDetailView(code: selection, repository: repository)
          .id(selection)
      } else {
        SelectCountryPlaceholder()
      }
    }
  }
}

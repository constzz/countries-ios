import AtlasDomain
import SwiftUI

/// The app's root screen. It owns the selection both columns share.
public struct RootView: View {
  private let repository: any CountriesRepository
  /// The selected country's code. Each window keeps its own and restores it after relaunch.
  @SceneStorage("selectedCountryCode") private var selection: String?

  public init(repository: any CountriesRepository) {
    self.repository = repository
  }

  public var body: some View {
    RootSplitView {
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

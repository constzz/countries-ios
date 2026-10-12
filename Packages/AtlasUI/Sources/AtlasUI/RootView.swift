import AtlasDomain
import SwiftUI

/// Owns the selection both columns share.
public struct RootView: View {
  private let getCountriesUseCase: GetCountriesUseCase
  private let getCountryDetailsUseCase: GetCountryDetailsUseCase
  /// The selected country's code. Each window keeps its own and restores it after relaunch.
  @SceneStorage("selectedCountryCode") private var selection: String?

  public init(getCountriesUseCase: GetCountriesUseCase, getCountryDetailsUseCase: GetCountryDetailsUseCase) {
    self.getCountriesUseCase = getCountriesUseCase
    self.getCountryDetailsUseCase = getCountryDetailsUseCase
  }

  public var body: some View {
    RootSplitView {
      CountryListView(getCountriesUseCase: getCountriesUseCase, selection: $selection)
    } detail: {
      if let selection {
        // A view, and so a view model, per country: nothing from the previous one can show.
        CountryDetailView(countryCode: selection, getCountryDetailsUseCase: getCountryDetailsUseCase)
          .id(selection)
      } else {
        SelectCountryPlaceholder()
      }
    }
  }
}

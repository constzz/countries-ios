import AtlasDomain
import SwiftUI

/// Owns the selection both columns share.
public struct RootView: View {
  private let getCountries: GetCountriesUseCase
  private let getCountryDetails: GetCountryDetailsUseCase
  /// The selected country's code. Each window keeps its own and restores it after relaunch.
  @SceneStorage("selectedCountryCode") private var selection: String?

  public init(getCountries: GetCountriesUseCase, getCountryDetails: GetCountryDetailsUseCase) {
    self.getCountries = getCountries
    self.getCountryDetails = getCountryDetails
  }

  public var body: some View {
    RootSplitView {
      CountryListView(getCountries: getCountries, selection: $selection)
    } detail: {
      if let selection {
        // A view, and so a view model, per country: nothing from the previous one can show.
        CountryDetailView(countryCode: selection, getCountryDetails: getCountryDetails)
          .id(selection)
      } else {
        SelectCountryPlaceholder()
      }
    }
  }
}

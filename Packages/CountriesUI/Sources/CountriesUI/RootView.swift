import CountriesDomain
import SwiftUI

/// The app's root screen.
public struct RootView: View {
  @Environment(\.countriesRepository) private var repository

  public init() {}

  public var body: some View {
    CountriesSplitView {
      CountryListView(repository: repository)
    }
  }
}

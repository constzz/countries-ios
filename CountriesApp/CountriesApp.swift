import CountriesUI
import SwiftUI

struct CountriesApp: App {
  private let container = AppContainer()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(\.countriesRepository, container.countriesRepository)
    }
  }
}

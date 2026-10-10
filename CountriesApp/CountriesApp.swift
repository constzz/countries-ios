import CountriesUI
import SwiftUI

@main
struct CountriesApp: App {
  private let container = AppContainer()

  var body: some Scene {
    WindowGroup {
      // Empty while the app hosts tests.
      if let repository = container.countriesRepository {
        RootView()
          .environment(\.countriesRepository, repository)
      }
    }
  }
}

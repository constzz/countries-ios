import CountriesUI
import SwiftUI

@main
struct CountriesApp: App {
  private let container = AppContainer()

  var body: some Scene {
    WindowGroup {
      if let repository = container.countriesRepository {
        RootView()
          .environment(\.countriesRepository, repository)
      } else {
        RootView()
      }
    }
  }
}

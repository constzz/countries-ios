import CountriesUI
import SwiftUI

struct CountriesApp: App {
  private let container = AppContainer(environment: AppEnvironment(bundle: .main))

  var body: some Scene {
    WindowGroup {
      RootView(repository: container.countriesRepository)
    }
  }
}

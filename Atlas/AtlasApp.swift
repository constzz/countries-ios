import AtlasUI
import SwiftUI

struct AtlasApp: App {
  private let container = AppContainer(environment: AppEnvironment(bundle: .main))

  var body: some Scene {
    WindowGroup {
      RootView(repository: container.countriesRepository)
    }
  }
}

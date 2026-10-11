import Foundation
import SwiftUI

/// The entry point. While the app hosts tests it runs an empty app instead, so no test builds the
/// app's dependencies or touches the network.
@main
enum AppLauncher {
  @MainActor
  static func main() {
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
      TestHostApp.main()
    } else {
      AtlasApp.main()
    }
  }
}

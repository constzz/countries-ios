import SwiftUI

/// The app tests run in: one empty window, whose scene snapshot tests draw in.
struct TestHostApp: App {
  var body: some Scene {
    WindowGroup {
      EmptyView()
    }
  }
}

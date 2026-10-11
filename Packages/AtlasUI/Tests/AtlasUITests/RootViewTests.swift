import SwiftUI
import Testing
@testable import AtlasUI

@Suite("RootView")
@MainActor
struct RootViewTests {
  @Test("AC-0.3 the test target runs in the test plan")
  func rootViewBuilds() {
    _ = RootView(repository: MockCountriesRepository()).body
  }
}

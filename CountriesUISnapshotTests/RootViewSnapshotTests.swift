import SwiftUI
import Testing
@testable import CountriesUI

@Suite(
  "RootView snapshots",
  .enabled(if: SnapshotEnvironment.isEnabled, SnapshotEnvironment.notReferenceReason)
)
@MainActor
struct RootViewSnapshotTests {
  @Test("AC-0.9 placeholder screen on every device preset, in light and dark")
  func placeholder() async {
    await assertSnapshots(of: RootView(), named: "ROOT_PLACEHOLDER", rightToLeft: true)
  }
}

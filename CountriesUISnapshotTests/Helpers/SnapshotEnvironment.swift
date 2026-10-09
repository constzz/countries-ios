import Foundation
import Testing

/// Where snapshot tests run, and whether they record new reference images.
enum SnapshotEnvironment {
  /// Reference images are recorded and compared only on Xcode 27.1 (Swift 6.4) with the iOS 27.0
  /// simulator, because rendering differs between OS versions.
  static var isReference: Bool {
    #if compiler(>=6.4)
      let version = ProcessInfo.processInfo.operatingSystemVersion
      return version.majorVersion == 27 && version.minorVersion == 0
    #else
      return false
    #endif
  }

  static let notReferenceReason: Comment = "Snapshots run only on Xcode 27.1 with the iOS 27.0 simulator."

  /// Set by the RecordSnapshots test plan.
  static var isRecording: Bool {
    ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
  }
}

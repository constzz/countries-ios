import Foundation
import os

extension Logger {
  /// Request failures, with the cause the user never sees.
  static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "atlas", category: "network")
}

import UIKit

// MARK: - SnapshotPreset

/// A device the snapshot tests render on. Sizes, safe areas and size classes were read from the
/// running simulators (Xcode 27.1), not taken from spec sheets.
struct SnapshotPreset: Sendable {
  let name: String
  let size: CGSize
  let scale: CGFloat
  let safeArea: UIEdgeInsets
  let horizontalSizeClass: UIUserInterfaceSizeClass
  let verticalSizeClass: UIUserInterfaceSizeClass
  let idiom: UIUserInterfaceIdiom
}

extension SnapshotPreset {
  /// iPhone 17 Pro in portrait (iOS 27.0).
  static let iPhone17Pro = SnapshotPreset(
    name: "iPhone17Pro",
    size: CGSize(width: 402, height: 874),
    scale: 3,
    safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
    horizontalSizeClass: .compact,
    verticalSizeClass: .regular,
    idiom: .phone
  )

  /// iPhone Duo folded: the cover screen in portrait (iOS 27.1).
  static let iPhoneDuoFolded = SnapshotPreset(
    name: "iPhoneDuoFolded",
    size: CGSize(width: 466, height: 678),
    scale: 3,
    safeArea: UIEdgeInsets(top: 82, left: 0, bottom: 34, right: 0),
    horizontalSizeClass: .compact,
    verticalSizeClass: .regular,
    idiom: .phone
  )

  /// iPhone Duo unfolded: the inner screen in the posture it opens in (iOS 27.1).
  static let iPhoneDuoUnfolded = SnapshotPreset(
    name: "iPhoneDuoUnfolded",
    size: CGSize(width: 951, height: 669),
    scale: 3,
    safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 84),
    horizontalSizeClass: .regular,
    verticalSizeClass: .regular,
    idiom: .phone
  )

  /// iPad (A16) and iPad Air 11-inch in portrait (iOS 27.0).
  static let iPad11Portrait = SnapshotPreset(
    name: "iPad11Portrait",
    size: CGSize(width: 820, height: 1180),
    scale: 2,
    safeArea: UIEdgeInsets(top: 32, left: 0, bottom: 20, right: 0),
    horizontalSizeClass: .regular,
    verticalSizeClass: .regular,
    idiom: .pad
  )

  /// iPad (A16) and iPad Air 11-inch in landscape (iOS 27.0).
  static let iPad11Landscape = SnapshotPreset(
    name: "iPad11Landscape",
    size: CGSize(width: 1180, height: 820),
    scale: 2,
    safeArea: UIEdgeInsets(top: 32, left: 0, bottom: 20, right: 0),
    horizontalSizeClass: .regular,
    verticalSizeClass: .regular,
    idiom: .pad
  )

  static let all: [SnapshotPreset] = [
    .iPhone17Pro, .iPhoneDuoFolded, .iPhoneDuoUnfolded, .iPad11Portrait, .iPad11Landscape,
  ]
}

import UIKit

/// The appearance, text size and layout direction of one snapshot image.
struct SnapshotVariant: Sendable {
  let suffix: String
  let style: UIUserInterfaceStyle
  let contentSize: UIContentSizeCategory
  let layoutDirection: UITraitEnvironmentLayoutDirection

  static let light = SnapshotVariant(
    suffix: "light", style: .light, contentSize: .large, layoutDirection: .leftToRight
  )
  static let dark = SnapshotVariant(
    suffix: "dark", style: .dark, contentSize: .large, layoutDirection: .leftToRight
  )
  static let lightAccessibilityXXXL = SnapshotVariant(
    suffix: "light_accessibilityXXXL",
    style: .light,
    contentSize: .accessibilityExtraExtraExtraLarge,
    layoutDirection: .leftToRight
  )
  static let lightRightToLeft = SnapshotVariant(
    suffix: "light_rtl", style: .light, contentSize: .large, layoutDirection: .rightToLeft
  )
}

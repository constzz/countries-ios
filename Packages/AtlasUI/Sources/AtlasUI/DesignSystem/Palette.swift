import SwiftUI

enum Palette {
  static var secondaryText: HierarchicalShapeStyle {
    .secondary
  }

  /// Main text where the system would style it as secondary.
  static var primaryText: HierarchicalShapeStyle {
    .primary
  }

  static var groupedBackground: Color {
    Color(.systemGroupedBackground)
  }
}

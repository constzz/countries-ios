import SwiftUI

extension ShapeStyle where Self == HierarchicalShapeStyle {
  static var secondaryText: HierarchicalShapeStyle {
    .secondary
  }

  /// Main text where the system would style it as secondary.
  static var primaryText: HierarchicalShapeStyle {
    .primary
  }
}

extension ShapeStyle where Self == Color {
  static var groupedBackground: Color {
    Color(.systemGroupedBackground)
  }
}

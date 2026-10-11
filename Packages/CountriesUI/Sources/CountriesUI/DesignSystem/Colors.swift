import SwiftUI

extension ShapeStyle where Self == HierarchicalShapeStyle {
  /// Supporting text under a title, such as a country's continent.
  static var secondaryText: HierarchicalShapeStyle {
    .secondary
  }

  /// Main text where the system would style it as secondary, such as a section header holding a
  /// country's name.
  static var primaryText: HierarchicalShapeStyle {
    .primary
  }
}

extension ShapeStyle where Self == Color {
  /// Behind a grouped list, such as the country detail, in every state.
  static var groupedBackground: Color {
    Color(.systemGroupedBackground)
  }
}

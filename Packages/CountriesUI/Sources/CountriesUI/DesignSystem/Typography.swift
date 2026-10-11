import SwiftUI

extension Font {
  /// A list row's main text, such as a country's name.
  static var rowTitle: Font {
    .body
  }

  /// A list row's supporting text, such as a country's continent.
  static var rowSubtitle: Font {
    .subheadline
  }

  /// The label beside an inline progress indicator, such as "Searching…".
  static var progressLabel: Font {
    .subheadline
  }

  /// A country's flag emoji in a list row. A text style, so it scales with Dynamic Type.
  static var rowFlag: Font {
    .title
  }

  /// A country's name in the detail's header.
  static var detailTitle: Font {
    .title.bold()
  }

  /// A country's flag emoji in the detail's header, at `size`. Scale the size with
  /// `@ScaledMetric(relativeTo: .largeTitle)`, so it follows Dynamic Type.
  static func detailFlag(size: CGFloat) -> Font {
    .system(size: size)
  }
}

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

  /// A country's flag emoji in a list row. A text style, so it scales with Dynamic Type.
  static var rowFlag: Font {
    .title
  }
}

import SwiftUI

extension Font {
  static var rowTitle: Font {
    .body
  }

  static var rowSubtitle: Font {
    .subheadline
  }

  static var progressLabel: Font {
    .subheadline
  }

  /// A text style, so it scales with Dynamic Type.
  static var rowFlag: Font {
    .title
  }

  static var detailTitle: Font {
    .title.bold()
  }

  /// A fixed `size`: it doesn't scale with Dynamic Type.
  static func detailFlag(size: CGFloat) -> Font {
    .system(size: size)
  }
}

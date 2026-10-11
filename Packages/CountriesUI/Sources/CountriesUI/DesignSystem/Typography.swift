import SwiftUI

enum Typography {
  enum Row {
    static var title: Font {
      .body
    }

    static var subtitle: Font {
      .subheadline
    }

    /// A text style, so it scales with Dynamic Type.
    static var flag: Font {
      .title
    }
  }

  enum Detail {
    static var title: Font {
      .title.bold()
    }

    /// A fixed `size`: it doesn't scale with Dynamic Type.
    static func flag(size: CGFloat) -> Font {
      .system(size: size)
    }
  }

  static var progressLabel: Font {
    .subheadline
  }
}

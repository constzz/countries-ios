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

    /// Exactly `size` points: the font adds no Dynamic Type scaling of its own.
    static func flag(size: CGFloat) -> Font {
      .system(size: size)
    }
  }

  static var progressLabel: Font {
    .subheadline
  }
}

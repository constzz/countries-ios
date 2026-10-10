import SwiftUI

extension View {
  /// Pins `label` with a progress indicator above the content while `isActive`, and keeps the
  /// content in place underneath. It sits in the content, not the toolbar: on iPhone an active
  /// search hides the navigation bar, and the indicator with it.
  func inlineProgress(_ isActive: Bool, label: Text) -> some View {
    safeAreaInset(edge: .top) {
      if isActive {
        InlineProgressView(label: label)
      }
    }
  }
}

private struct InlineProgressView: View {
  let label: Text

  var body: some View {
    HStack {
      ProgressView()
      label
        .font(.progressLabel)
        .foregroundStyle(.secondaryText)
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .modifier(CapsuleBackground())
    .accessibilityElement(children: .combine)
  }
}

/// Liquid Glass where the system has it, the regular material before.
private struct CapsuleBackground: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26, *) {
      content.glassEffect(.regular, in: .capsule)
    } else {
      content.background(.regularMaterial, in: .capsule)
    }
  }
}

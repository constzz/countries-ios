import SwiftUI

/// The top of the detail: the flag above the name. VoiceOver reads it as a heading with the name,
/// without the flag. It reports when the name scrolls under the navigation bar, whose bottom edge is
/// at `barBottom` in global coordinates, so the bar can show the name instead.
struct CountryDetailHeader: View {
  let name: String
  let flag: String
  let barBottom: CGFloat
  let scrolledUnderBar: (Bool) -> Void

  @ScaledMetric(relativeTo: .largeTitle) private var flagSize: CGFloat = 80

  var body: some View {
    VStack {
      Text(verbatim: flag)
        .font(Typography.Detail.flag(size: flagSize))
        .accessibilityHidden(true)
      Text(verbatim: name)
        .font(Typography.Detail.title)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)
        .onGeometryChange(for: Bool.self) { proxy in
          proxy.frame(in: .global).maxY < barBottom
        } action: { isUnderBar in
          scrolledUnderBar(isUnderBar)
        }
    }
    .frame(maxWidth: .infinity)
  }
}

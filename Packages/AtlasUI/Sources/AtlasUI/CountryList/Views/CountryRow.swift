import AtlasDomain
import SwiftUI

/// One country in the list: flag, name and continent. VoiceOver reads it as one element, name
/// then continent, without the flag.
struct CountryRow: View {
  let country: CountrySummary

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var flag: some View {
    Text(verbatim: country.emoji)
      .font(Typography.Row.flag)
      .accessibilityHidden(true)
  }

  private var details: some View {
    VStack(alignment: .leading) {
      Text(verbatim: country.name)
        .font(Typography.Row.title)
      Text(verbatim: country.continent.name)
        .font(Typography.Row.subtitle)
        .foregroundStyle(Palette.secondaryText)
    }
  }

  var body: some View {
    Group {
      // At accessibility sizes the flag beside the name leaves too little width, and names
      // break mid-word, so the flag goes above.
      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading) {
          flag
          details
        }
      } else {
        Label {
          details
        } icon: {
          flag
        }
      }
    }
    .accessibilityElement(children: .combine)
  }
}

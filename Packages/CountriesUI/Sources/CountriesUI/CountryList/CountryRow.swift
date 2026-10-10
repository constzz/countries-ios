import CountriesDomain
import SwiftUI

/// One country in the list: flag, name and continent. VoiceOver reads it as one element, name
/// then continent, without the flag.
struct CountryRow: View {
  let country: CountrySummary

  var body: some View {
    Label {
      VStack(alignment: .leading) {
        Text(verbatim: country.name)
          .font(.rowTitle)
        Text(verbatim: country.continent.name)
          .font(.rowSubtitle)
          .foregroundStyle(.secondaryText)
      }
    } icon: {
      Text(verbatim: country.emoji)
        .font(.rowFlag)
        .accessibilityHidden(true)
    }
    .accessibilityElement(children: .combine)
  }
}

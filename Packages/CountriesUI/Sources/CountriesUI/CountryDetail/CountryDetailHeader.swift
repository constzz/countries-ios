import CountriesDomain
import SwiftUI

/// The top of the detail: the flag above the name. VoiceOver reads it as a heading with the name,
/// without the flag.
struct CountryDetailHeader: View {
  let country: CountrySummary

  @ScaledMetric(relativeTo: .largeTitle) private var flagSize: CGFloat = 80

  var body: some View {
    VStack {
      Text(verbatim: country.emoji)
        .font(.detailFlag(size: flagSize))
        .accessibilityHidden(true)
      Text(verbatim: country.name)
        .font(.detailTitle)
        .multilineTextAlignment(.center)
        .accessibilityAddTraits(.isHeader)
    }
    .frame(maxWidth: .infinity)
  }
}

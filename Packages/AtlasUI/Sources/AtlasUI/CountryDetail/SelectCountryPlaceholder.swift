import SwiftUI

/// The detail column before any country is selected, so it's never blank.
struct SelectCountryPlaceholder: View {
  var body: some View {
    ContentUnavailableView {
      Label {
        Text(.countryDetailPlaceholder)
      } icon: {
        Image(systemName: "globe")
      }
    }
  }
}

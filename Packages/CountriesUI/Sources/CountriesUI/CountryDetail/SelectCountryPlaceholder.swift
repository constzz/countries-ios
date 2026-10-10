import SwiftUI

/// The detail column before any country is selected, so it's never blank.
struct SelectCountryPlaceholder: View {
  var body: some View {
    ContentUnavailableView {
      Label {
        Text(
          "Select a Country",
          bundle: .module,
          comment: "Placeholder in the detail column when no country is selected."
        )
      } icon: {
        Image(systemName: "globe")
      }
    }
  }
}

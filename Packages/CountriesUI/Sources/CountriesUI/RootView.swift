import SwiftUI

/// The app's root screen. A placeholder until the country list arrives.
public struct RootView: View {
  public init() {}

  public var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label {
          Text("Countries", bundle: .module, comment: "The app's name, shown as the root screen's title.")
        } icon: {
          Image(systemName: "globe")
        }
      } description: {
        Text(
          "Browse every country in the world.",
          bundle: .module,
          comment: "Placeholder description under the app name on the root screen."
        )
      }
      .navigationTitle(
        Text("Countries", bundle: .module, comment: "The app's name, shown as the root screen's title.")
      )
    }
  }
}

#Preview {
  RootView()
}

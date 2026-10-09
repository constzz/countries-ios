import SwiftUI

/// The app's root screen. A placeholder until the country list arrives.
public struct RootView: View {
  public init() {}

  public var body: some View {
    NavigationStack {
      ContentUnavailableView {
        Label {
          Text(verbatim: "Countries")
        } icon: {
          Image(systemName: "globe")
        }
      } description: {
        Text(verbatim: "Browse every country in the world.")
      }
      .navigationTitle(Text(verbatim: "Countries"))
    }
  }
}

#Preview {
  RootView()
}

import SwiftUI

/// The list in the sidebar and the selected country in the detail column. On compact width it
/// collapses into a navigation stack by itself.
struct CountriesSplitView<Sidebar: View>: View {
  /// Both columns, so iPad portrait shows the list too; people can still hide the sidebar.
  @State private var columnVisibility = NavigationSplitViewVisibility.all
  private let sidebar: Sidebar

  init(@ViewBuilder sidebar: () -> Sidebar) {
    self.sidebar = sidebar()
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
    } detail: {
      SelectCountryPlaceholder()
    }
  }
}

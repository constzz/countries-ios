import SwiftUI

/// The list in the sidebar and the selected country in the detail column. On compact width it
/// collapses into a navigation stack by itself.
struct RootSplitView<Sidebar: View, Detail: View>: View {
  /// Both columns, so iPad portrait shows the list too; people can still hide the sidebar.
  @State private var columnVisibility = NavigationSplitViewVisibility.all
  private let sidebar: Sidebar
  private let detail: Detail

  init(@ViewBuilder sidebar: () -> Sidebar, @ViewBuilder detail: () -> Detail) {
    self.sidebar = sidebar()
    self.detail = detail()
  }

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      sidebar
    } detail: {
      detail
    }
  }
}

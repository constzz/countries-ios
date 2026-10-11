import AtlasDomain
import SwiftUI

struct CountryListView: View {
  @State private var viewModel: CountryListViewModel
  @Binding private var selection: String?

  init(repository: any CountriesRepository, selection: Binding<String?>) {
    _viewModel = State(initialValue: CountryListViewModel(repository: repository))
    _selection = selection
  }

  var body: some View {
    CountryListContent(state: viewModel.state, selection: $selection, send: viewModel.send)
      .onAppear {
        viewModel.send(.appeared)
      }
      .task {
        for await effect in viewModel.effects() {
          handle(effect)
        }
      }
  }

  private func handle(_ effect: CountryListEffect) {
    switch effect {
    case let .announce(text):
      AccessibilityNotification.Announcement(text).post()
    }
  }
}

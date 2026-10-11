import AtlasDomain
import SwiftUI

/// The country list screen: owns its view model, starts loading when it appears and handles the
/// view model's effects.
struct CountryListView: View {
  @State private var viewModel: CountryListViewModel
  @Binding private var selection: String?

  init(repository: any CountriesRepository, selection: Binding<String?>) {
    _viewModel = State(initialValue: CountryListViewModel(repository: repository))
    _selection = selection
  }

  var body: some View {
    CountryListContent(state: viewModel.state, selection: $selection, send: viewModel.send)
      .task {
        // Subscribe first: an effect emitted while no one listens is dropped.
        let effects = viewModel.effects()
        viewModel.send(.appeared)
        for await effect in effects {
          handle(effect)
        }
      }
  }

  private func handle(_ effect: CountryListEffect) {
    switch effect {
    case let .announce(resultCount):
      AccessibilityNotification.Announcement(SearchAnnouncement.text(forResultCount: resultCount)).post()
    }
  }
}

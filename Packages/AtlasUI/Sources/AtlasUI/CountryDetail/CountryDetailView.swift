import AtlasDomain
import SwiftUI

/// The country detail screen: owns its view model, loads the country when it appears and cancels
/// the request when it disappears.
struct CountryDetailView: View {
  @State private var viewModel: CountryDetailViewModel

  init(code: String, repository: any CountriesRepository) {
    _viewModel = State(initialValue: CountryDetailViewModel(code: code, repository: repository))
  }

  var body: some View {
    CountryDetailContent(state: viewModel.state, send: viewModel.send)
      // The screen has no effects to subscribe to.
      .task {
        viewModel.send(.appeared)
      }
      .onDisappear {
        viewModel.send(.disappeared)
      }
  }
}

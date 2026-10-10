import CountriesDomain
import SwiftUI

/// The country list screen: owns its view model and starts loading when it appears.
struct CountryListView: View {
  @State private var viewModel: CountryListViewModel

  init(repository: any CountriesRepository) {
    _viewModel = State(initialValue: CountryListViewModel(repository: repository))
  }

  var body: some View {
    CountryListContent(state: viewModel.state, send: viewModel.send)
      .task {
        viewModel.send(.appeared)
      }
  }
}

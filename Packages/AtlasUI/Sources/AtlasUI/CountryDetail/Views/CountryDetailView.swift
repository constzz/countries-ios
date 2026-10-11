import AtlasDomain
import SwiftUI

struct CountryDetailView: View {
  @State private var viewModel: CountryDetailViewModel

  init(countryCode: String, repository: any CountriesRepository) {
    _viewModel = State(initialValue: CountryDetailViewModel(countryCode: countryCode, repository: repository))
  }

  var body: some View {
    CountryDetailContent(state: viewModel.state, send: viewModel.send)
      .task {
        viewModel.send(.appeared)
      }
      .onDisappear {
        viewModel.send(.disappeared)
      }
  }
}

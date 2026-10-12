import AtlasDomain
import SwiftUI

struct CountryDetailView: View {
  @State private var viewModel: CountryDetailViewModel

  init(countryCode: String, getCountryDetails: GetCountryDetailsUseCase) {
    _viewModel = State(initialValue: CountryDetailViewModel(
      countryCode: countryCode,
      getCountryDetails: getCountryDetails
    ))
  }

  var body: some View {
    CountryDetailContent(state: viewModel.state, send: viewModel.send)
      .onAppear {
        viewModel.send(.appeared)
      }
      .onDisappear {
        viewModel.send(.disappeared)
      }
  }
}

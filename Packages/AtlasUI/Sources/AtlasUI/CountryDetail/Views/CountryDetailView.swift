import AtlasDomain
import SwiftUI

struct CountryDetailView: View {
  @State private var viewModel: CountryDetailViewModel

  init(countryCode: String, getCountryDetailsUseCase: GetCountryDetailsUseCase) {
    _viewModel = State(initialValue: CountryDetailViewModel(
      countryCode: countryCode,
      getCountryDetailsUseCase: getCountryDetailsUseCase
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

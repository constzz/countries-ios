import AtlasDomain
import SwiftUI
import Testing
@testable import AtlasUI

@Suite("RootView")
@MainActor
struct RootViewTests {
  @Test("AC-0.3 the test target runs in the test plan")
  func rootViewBuilds() {
    let sut = makeSUT()

    _ = sut.body
  }

  private func makeSUT() -> RootView {
    let repository = MockCountriesRepository()
    return RootView(
      getCountriesUseCase: GetCountriesUseCase(repository: repository),
      getCountryDetailsUseCase: GetCountryDetailsUseCase(repository: repository)
    )
  }
}

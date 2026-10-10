import CountriesDomain

/// The country detail's view model. It loads one country, by its code, from its own query.
final class CountryDetailViewModel: MVIViewModel<CountryDetailState, CountryDetailAction, CountryDetailEffect> {
  private let code: String
  private let repository: any CountriesRepository

  /// Stores the dependencies and does nothing else: SwiftUI builds a view's initial `@State` value
  /// every time it creates the view.
  init(code: String, repository: any CountriesRepository) {
    self.code = code
    self.repository = repository
    super.init(initialState: CountryDetailState())
  }

  override func reduce(_ current: CountryDetailState, _: CountryDetailAction) -> CountryDetailState {
    current
  }
}

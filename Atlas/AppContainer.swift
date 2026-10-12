import AtlasData
import AtlasDomain

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  let getCountriesUseCase: GetCountriesUseCase
  let getCountryDetailsUseCase: GetCountryDetailsUseCase

  init(environment: AppEnvironment) {
    let repository = makeCountriesRepository(endpoint: environment.countriesAPIURL)
    getCountriesUseCase = GetCountriesUseCase(repository: repository)
    getCountryDetailsUseCase = GetCountryDetailsUseCase(repository: repository)
  }
}

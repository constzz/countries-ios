import AtlasData
import AtlasDomain

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  let getCountries: GetCountriesUseCase
  let getCountryDetails: GetCountryDetailsUseCase

  init(environment: AppEnvironment) {
    let repository = makeCountriesRepository(endpoint: environment.countriesAPIURL)
    getCountries = GetCountriesUseCase(repository: repository)
    getCountryDetails = GetCountryDetailsUseCase(repository: repository)
  }
}

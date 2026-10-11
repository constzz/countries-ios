import AtlasData
import AtlasDomain

/// The composition root: builds the app's dependencies. Startup does nothing else.
struct AppContainer {
  let countriesRepository: any CountriesRepository

  init(environment: AppEnvironment) {
    countriesRepository = makeCountriesRepository(endpoint: environment.countriesAPIURL)
  }
}

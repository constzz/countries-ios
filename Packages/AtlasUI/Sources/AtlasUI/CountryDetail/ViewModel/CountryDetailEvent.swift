import AtlasDomain
import AtlasMVI

enum CountryDetailEvent: MVIEvent {
  case countryLoaded(CountryDetails)
  case countryFailedToLoad(RequestError)
}

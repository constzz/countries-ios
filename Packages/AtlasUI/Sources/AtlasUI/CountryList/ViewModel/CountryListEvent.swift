import AtlasDomain
import AtlasMVI

enum CountryListEvent: MVIEvent {
  /// The search pipe settled on a trimmed term.
  case searchSettled(String)
  /// A search is still running long enough after it started to show its progress.
  case searchProgressDue
  case countriesLoaded([CountrySummary], request: CountriesRequest)
  case countriesFailedToLoad(RequestError)
}

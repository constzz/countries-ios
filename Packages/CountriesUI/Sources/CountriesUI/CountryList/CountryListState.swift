import CountriesDomain

/// What the country list shows.
enum CountryListState: Equatable {
  /// Nothing requested yet.
  case idle
  /// The first load, with no rows to keep on screen.
  case loading
  case loaded([CountrySummary])
  /// The search for `query` matched no country.
  case empty(query: String)
  case failed(CountriesError)
}

/// One fetch of the country list.
struct CountriesRequest: Equatable {
  enum Kind: Equatable {
    case load, search, refresh
  }

  let id: Int
  let term: String
  let forceRefresh: Bool
  let kind: Kind
}

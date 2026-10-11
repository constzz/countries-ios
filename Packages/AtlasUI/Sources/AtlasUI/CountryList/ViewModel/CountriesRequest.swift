struct CountriesRequest: Equatable {
  enum Kind: Equatable {
    case load, search, refresh
  }

  let term: String
  let kind: Kind

  var forceRefresh: Bool {
    kind == .refresh
  }
}

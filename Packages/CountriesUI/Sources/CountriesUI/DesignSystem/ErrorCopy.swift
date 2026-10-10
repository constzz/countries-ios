import CountriesDomain

/// What an error state says. The domain error carries no text; this is where it gets its copy.
struct ErrorCopy: Equatable {
  let title: String
  let message: String
  let systemImage: String

  init(_: CountriesError) {
    title = ""
    message = ""
    systemImage = ""
  }
}

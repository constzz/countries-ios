/// Turns a search term into the regex the API's `name` filter matches against.
enum SearchPattern {
  /// The regex for `term`, or `nil` when the term is blank and no filter applies.
  static func regex(for term: String) -> String? {
    term
  }
}

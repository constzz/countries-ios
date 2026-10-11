import Foundation

/// Turns a search term into the regex the API's `name` filter matches against.
///
/// The API's regex is case-sensitive and has no case-insensitive flag (`(?i)` is a server error),
/// so each cased letter becomes a class of both cases. Metacharacters are escaped: the term is
/// matched literally, and an unbalanced `(` can't reach the server.
enum SearchPattern {
  private static let metacharacters: Set<Character> = [
    "\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "[", "]", "{", "}",
  ]

  /// The regex for `term`, or `nil` when the term is blank and no filter applies.
  static func regex(for term: String) -> String? {
    let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }
    return trimmed.map(pattern(for:)).joined()
  }

  private static func pattern(for character: Character) -> String {
    if metacharacters.contains(character) {
      return "\\\(character)"
    }
    let lower = character.lowercased()
    let upper = character.uppercased()
    // A class can only hold single code points: letters such as "ß" ("SS") pass through.
    guard lower != upper, lower.unicodeScalars.count == 1, upper.unicodeScalars.count == 1 else {
      return String(character)
    }
    return "[\(lower)\(upper)]"
  }
}

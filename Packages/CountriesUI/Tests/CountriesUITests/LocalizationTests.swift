import Foundation
import Testing
@testable import CountriesUI

/// Checks the String Catalog against the bundle the app ships. Every language the bundle ships,
/// English included, must have a value for every key. English is the source language and its keys
/// are the English text, but a key with no English value in the compiled table only displays by
/// falling back to the key, and "Show non-localized strings" flags it.
@Suite("Localization")
struct LocalizationTests {
  @Test("AC-0.10 AC-1.10 every catalog key has a value in every language the bundle ships, English included")
  func everyKeyIsTranslatedInEveryLanguage() throws {
    let catalog = try StringCatalog.load()
    #expect(Bundle.module.developmentLocalization == catalog.sourceLanguage)

    let translations = Bundle.module.localizations.filter { $0 != "Base" }
    #expect(translations.contains(catalog.sourceLanguage))
    let missing = "\u{0}missing"
    for localization in translations {
      let path = try #require(
        Bundle.module.path(forResource: localization, ofType: "lproj"),
        "No \(localization).lproj in the bundle"
      )
      let bundle = try #require(Bundle(path: path))
      for key in catalog.strings.keys {
        let value = bundle.localizedString(forKey: key, value: missing, table: nil)
        #expect(value != missing, "\(localization) has no value for “\(key)”")
      }
    }
  }

  @Test("AC-0.10 no catalog key is stale, and every key has a translator comment")
  func everyKeyIsCurrentAndCommented() throws {
    let catalog = try StringCatalog.load()
    #expect(!catalog.strings.isEmpty)
    for (key, entry) in catalog.strings {
      #expect(entry.extractionState != "stale", "“\(key)” is stale: no code uses it")
      #expect(
        !(entry.comment ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        "“\(key)” has no translator comment"
      )
    }
  }
}

/// The parts of `Localizable.xcstrings` the tests read.
private struct StringCatalog: Decodable {
  struct Entry: Decodable {
    let comment: String?
    let extractionState: String?
  }

  let sourceLanguage: String
  let strings: [String: Entry]

  static func load(filePath: String = #filePath) throws -> StringCatalog {
    let packageRoot = URL(filePath: filePath)
      .deletingLastPathComponent() // CountriesUITests
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // CountriesUI
    let url = packageRoot.appending(path: "Sources/CountriesUI/Resources/Localizable.xcstrings")
    return try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: url))
  }
}

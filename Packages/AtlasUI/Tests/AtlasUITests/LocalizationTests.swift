import Foundation
import Testing
@testable import AtlasUI

/// Checks the String Catalog against the bundle the app ships and the code that uses it. Every
/// language the bundle ships, English included, must have a value for every key: keys are short
/// names, so a key with no English value would display as its name.
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

  @Test("AC-0.10 every catalog key is a short name added in the catalog, with a translator comment")
  func everyKeyIsAShortNameWithAComment() throws {
    let catalog = try StringCatalog.load()
    #expect(!catalog.strings.isEmpty)
    for (key, entry) in catalog.strings {
      let isShortKey = key.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { part in
        part.first?.isLowercase == true && part.allSatisfy { $0.isASCII && $0.isLetter }
      }
      #expect(isShortKey, "“\(key)” isn't a short key such as countryList.title")
      #expect(
        entry.extractionState == "manual",
        "“\(key)” wasn't added in the catalog, so Xcode generates no symbol for it"
      )
      #expect(
        !(entry.comment ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        "“\(key)” has no translator comment"
      )
    }
  }

  /// Xcode never marks a key added in the catalog as stale, so this finds the unused ones.
  @Test("AC-0.10 the code uses every catalog key's generated symbol")
  func everyKeyIsUsed() throws {
    let catalog = try StringCatalog.load()
    let sources = try AtlasUISources.load()
    for key in catalog.strings.keys {
      let symbol = StringCatalog.symbol(forKey: key)
      let use = try Regex("\\.\(symbol)\\b")
      #expect(sources.contains(use), "No code uses “\(key)” (.\(symbol))")
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

  static func load() throws -> StringCatalog {
    let url = packageRoot.appending(path: "Sources/AtlasUI/Resources/Localizable.xcstrings")
    return try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: url))
  }

  /// The name of the symbol Xcode generates for a key: `countryList.title` is `countryListTitle`.
  static func symbol(forKey key: String) -> String {
    key.split(separator: ".").enumerated().map { index, part in
      index == 0 ? String(part) : part.prefix(1).uppercased() + part.dropFirst()
    }.joined()
  }
}

/// The Swift sources of the AtlasUI target, joined into one string.
private enum AtlasUISources {
  static func load() throws -> String {
    let sources = packageRoot.appending(path: "Sources/AtlasUI")
    let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
    return try files.compactMap { $0 as? URL }
      .filter { $0.pathExtension == "swift" }
      .map { try String(contentsOf: $0, encoding: .utf8) }
      .joined(separator: "\n")
  }
}

private let packageRoot = URL(filePath: #filePath)
  .deletingLastPathComponent() // AtlasUITests
  .deletingLastPathComponent() // Tests
  .deletingLastPathComponent() // AtlasUI

import Testing
@testable import AtlasData

@Suite("SearchPattern")
struct SearchPatternTests {
  @Test("AC-1.3 letters match either case")
  func lettersMatchEitherCase() {
    #expect(SearchPattern.regex(for: "ger") == "[gG][eE][rR]")
    #expect(SearchPattern.regex(for: "Ger") == "[gG][eE][rR]")
    #expect(SearchPattern.regex(for: "Åland") == "[åÅ][lL][aA][nN][dD]")
  }

  @Test("AC-1.3 regex metacharacters are escaped")
  func metacharactersAreEscaped() {
    #expect(SearchPattern.regex(for: "(") == #"\("#)
    #expect(SearchPattern.regex(for: "C++") == #"[cC]\+\+"#)
    #expect(SearchPattern.regex(for: #"\^$.|?*+()[]{}"#) == #"\\\^\$\.\|\?\*\+\(\)\[\]\{\}"#)
  }

  @Test("AC-1.3 a blank term means no filter")
  func blankTermMeansNoFilter() {
    #expect(SearchPattern.regex(for: "") == nil)
    #expect(SearchPattern.regex(for: " \t\n") == nil)
  }

  @Test("AC-1.3 the term is trimmed and inner spaces are kept")
  func termIsTrimmed() {
    #expect(SearchPattern.regex(for: "  new z ") == "[nN][eE][wW] [zZ]")
  }

  @Test("AC-1.3 characters without a one-to-one case mapping pass through")
  func uncasedCharactersPassThrough() {
    #expect(SearchPattern.regex(for: "ß") == "ß")
    #expect(SearchPattern.regex(for: "4-é") == "4-[éÉ]")
  }
}

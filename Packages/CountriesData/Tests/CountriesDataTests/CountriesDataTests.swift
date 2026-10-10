import Testing
@testable import CountriesData

@Suite("CountriesData")
struct CountriesDataTests {
  @Test("AC-0.3 the test target runs in the test plan")
  func targetRuns() {
    #expect(Bool(true))
  }
}

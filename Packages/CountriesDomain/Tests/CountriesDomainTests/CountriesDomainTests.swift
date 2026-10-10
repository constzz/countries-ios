import Testing
@testable import CountriesDomain

@Suite("CountriesDomain")
struct CountriesDomainTests {
  @Test("AC-0.3 the test target runs in the test plan")
  func targetRuns() {
    #expect(Bool(true))
  }
}

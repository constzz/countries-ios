import Testing
@testable import AtlasData

@Suite("InMemoryCache")
struct InMemoryCacheTests {
  @Test("returns the value stored for a key, and nothing for another")
  func returnsTheStoredValue() async {
    let sut = InMemoryCache<String, Int>()

    await sut.insert(1, for: "a")

    #expect(await sut.value(for: "a") == 1)
    #expect(await sut.value(for: "b") == nil)
  }

  @Test("a new value for a key replaces the old one")
  func newValueReplacesTheOld() async {
    let sut = InMemoryCache<String, Int>()
    await sut.insert(1, for: "a")

    await sut.insert(2, for: "a")

    #expect(await sut.value(for: "a") == 2)
  }
}

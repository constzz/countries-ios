actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {
  private var values: [Key: Value] = [:]

  func value(for key: Key) -> Value? {
    values[key]
  }

  func insert(_ value: Value, for key: Key) {
    values[key] = value
  }
}

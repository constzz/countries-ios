/// Why loading countries failed. It carries no user-facing text: the UI chooses the copy.
///
/// Cancellation is not a failure, so it has no case here: a cancelled request throws
/// `CancellationError` and never becomes an error state.
public enum CountriesError: Error, Equatable, Sendable {
  /// The device is offline or lost its connection.
  case offline
  /// Any other transport or HTTP failure, including a timeout.
  case network
  /// The response has GraphQL errors, or no data.
  case server
  /// The requested country doesn't exist.
  case notFound
  /// The response doesn't have the expected shape.
  case decoding
  case unknown
}

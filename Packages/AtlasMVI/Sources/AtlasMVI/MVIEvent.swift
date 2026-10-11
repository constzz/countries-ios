/// Something the view model's own work produced: a response, a settled search, a timer. Views
/// never send one.
public protocol MVIEvent: Equatable, Sendable {}

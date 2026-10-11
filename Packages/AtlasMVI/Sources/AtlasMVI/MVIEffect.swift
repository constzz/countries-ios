/// A one-time UI event the view handles. Anything the screen must still show after a redraw
/// belongs in the state instead.
public protocol MVIEffect: Equatable, Sendable {}

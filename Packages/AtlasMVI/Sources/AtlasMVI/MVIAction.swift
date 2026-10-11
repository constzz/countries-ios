/// Something the user did or the screen went through, sent by the view and named after what
/// happened: `.appeared`, `.retryTapped`. Never a command.
public protocol MVIAction: Equatable, Sendable {}

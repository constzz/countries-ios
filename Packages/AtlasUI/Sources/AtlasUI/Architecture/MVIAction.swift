/// Something that happened on a screen, named after the event: `.appeared`, `.retryTapped`,
/// `.responseReceived`. Never a command.
protocol MVIAction: Equatable, Sendable {}

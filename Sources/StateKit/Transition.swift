import Foundation

/// A valid state transition triggered by an event
///
/// ```swift
/// Transition(from: .pending, on: .confirm, to: .confirmed) {
///     try await notifyUser()
/// }
/// ```
public struct Transition<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable, CustomDebugStringConvertible {
    /// The source state
    public let from: State

    /// The triggering event
    public let event: Event

    /// The destination state
    public let to: State

    /// An optional async side effect executed during the transition
    public let sideEffect: (@Sendable () async throws -> Void)?

    /// Create a transition
    public init(
        from: State,
        on event: Event,
        to: State,
        sideEffect: (@Sendable () async throws -> Void)? = nil
    ) {
        self.from = from
        self.event = event
        self.to = to
        self.sideEffect = sideEffect
    }

    public var debugDescription: String {
        "Transition(\(from) --\(event)--> \(to))"
    }
}

import Foundation

/// Configuration for an automatic timeout transition
public struct TimeoutTransition<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// The state that triggers the timeout
    public let from: State

    /// The state to transition to on timeout
    public let to: State

    /// The event to synthesize when the timeout fires
    public let event: Event

    /// Duration before the timeout fires
    public let duration: Duration

    /// Create a timeout transition
    public init(from: State, after duration: Duration, on event: Event, to: State) {
        self.from = from
        self.to = to
        self.event = event
        self.duration = duration
    }
}

extension StateMachine {
    /// Register a timeout transition that fires automatically after a duration
    ///
    /// When the machine enters `from`, a timer starts. If still in that state
    /// when the timer fires, the `event` is automatically sent.
    public func addTimeout(_ timeout: TimeoutTransition<State, Event>) {
        let machine = self
        onTransition { @Sendable _, _, newState in
            if newState == timeout.from {
                Task {
                    try? await Task.sleep(for: timeout.duration)
                    let current = await machine.currentState
                    if current == timeout.from {
                        _ = try? await machine.send(timeout.event)
                    }
                }
            }
        }
    }
}

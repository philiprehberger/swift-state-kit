import Foundation

extension StateMachine {
    /// Send a sequence of events in order, returning the final state
    ///
    /// Each event is applied one at a time via ``send(_:)``. If an event is invalid in the
    /// state reached so far, this method throws and any events applied before it remain
    /// committed — the machine is left in the state reached by the last successful event.
    ///
    /// Useful for scripted flows or replaying a recorded event log.
    ///
    /// - Parameter events: The events to apply, in order
    /// - Returns: The state after the final event, or the current state if `events` is empty
    /// - Throws: Any error thrown by ``send(_:)``, including
    ///           `StateMachineError.invalidTransition` for the first invalid event
    @discardableResult
    public func send(_ events: [Event]) async throws -> State {
        var result = currentState
        for event in events {
            result = try await send(event)
        }
        return result
    }
}

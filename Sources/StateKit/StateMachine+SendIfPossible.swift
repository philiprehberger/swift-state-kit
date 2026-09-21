import Foundation

extension StateMachine {
    /// Send an event, returning `nil` instead of throwing when no transition applies
    ///
    /// Behaves exactly like ``send(_:)`` when a transition matches — running middleware, side
    /// effects, entry and exit actions, and recording history. When no transition matches the
    /// current state, the machine is left untouched and `nil` is returned rather than
    /// `StateMachineError.invalidTransition` being thrown.
    ///
    /// Useful when events arrive from a source that does not track the machine's state — a UI
    /// or an event feed — where an inapplicable event is expected rather than exceptional.
    /// Errors from side effects, middleware, and entry/exit actions still propagate.
    ///
    /// - Parameter event: The event to send
    /// - Returns: The new state, or `nil` if no transition applies
    /// - Throws: `StateMachineError.sideEffectFailed` if a side effect throws, or any error
    ///           thrown by middleware or entry/exit actions
    @discardableResult
    public func sendIfPossible(_ event: Event) async throws -> State? {
        do {
            return try await send(event)
        } catch let error as StateMachineError where error.isInvalidTransition {
            return nil
        }
    }
}

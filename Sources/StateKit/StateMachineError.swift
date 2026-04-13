import Foundation

/// Errors thrown by the state machine
public enum StateMachineError: Error, Sendable, CustomStringConvertible {
    /// The event is not valid in the current state
    case invalidTransition(from: String, event: String)

    /// A side effect threw an error during transition
    case sideEffectFailed(Error)

    /// Attempted to undo with no history available
    case noHistoryToUndo

    public var description: String {
        switch self {
        case .invalidTransition(let from, let event):
            return "Invalid transition: cannot handle '\(event)' in state '\(from)'"
        case .sideEffectFailed(let error):
            return "Side effect failed: \(error)"
        case .noHistoryToUndo:
            return "No history available to undo"
        }
    }
}

import Foundation

/// Errors thrown by the state machine
public enum StateMachineError: Error, Sendable, CustomStringConvertible, Equatable {
    /// The event is not valid in the current state
    case invalidTransition(from: String, event: String)

    /// A side effect threw an error during transition
    case sideEffectFailed(Error)

    /// Attempted to undo with no history available
    case noHistoryToUndo

    /// Attempted to restore to an invalid state
    case invalidState(String)

    public var description: String {
        switch self {
        case .invalidTransition(let from, let event):
            return "Invalid transition: cannot handle '\(event)' in state '\(from)'"
        case .sideEffectFailed(let error):
            return "Side effect failed: \(error)"
        case .noHistoryToUndo:
            return "No history available to undo"
        case .invalidState(let state):
            return "Invalid state for restore: '\(state)'"
        }
    }

    /// Whether this is an invalid transition error
    public var isInvalidTransition: Bool {
        if case .invalidTransition = self { return true }
        return false
    }

    /// Whether this is a side effect failure
    public var isSideEffectFailed: Bool {
        if case .sideEffectFailed = self { return true }
        return false
    }

    public static func == (lhs: StateMachineError, rhs: StateMachineError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidTransition(let lf, let le), .invalidTransition(let rf, let re)):
            return lf == rf && le == re
        case (.sideEffectFailed(let le), .sideEffectFailed(let re)):
            return String(describing: le) == String(describing: re)
        case (.noHistoryToUndo, .noHistoryToUndo):
            return true
        case (.invalidState(let ls), .invalidState(let rs)):
            return ls == rs
        default:
            return false
        }
    }
}

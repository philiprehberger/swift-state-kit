import Foundation

/// A serializable snapshot of a state machine's current state
public struct StateMachineSnapshot<State: Codable & Hashable & Sendable>: Codable, Sendable {
    /// The current state when the snapshot was taken
    public let currentState: State

    /// When the snapshot was created
    public let timestamp: Date

    public init(currentState: State, timestamp: Date = Date()) {
        self.currentState = currentState
        self.timestamp = timestamp
    }
}

extension StateMachine where State: Codable {
    /// Create a serializable snapshot of the current state
    public func snapshot() -> StateMachineSnapshot<State> {
        StateMachineSnapshot(currentState: currentState)
    }

    /// Restore the state machine from a snapshot
    ///
    /// - Throws: `StateMachineError.invalidState` if the restored state has no transitions
    public func restore(from snapshot: StateMachineSnapshot<State>) throws {
        let hasTransitions = transitions.contains { $0.from == snapshot.currentState || $0.to == snapshot.currentState }
        guard hasTransitions || snapshot.currentState == initialState else {
            throw StateMachineError.invalidState(String(describing: snapshot.currentState))
        }
        currentState = snapshot.currentState
        stateHistory.clear()
    }
}

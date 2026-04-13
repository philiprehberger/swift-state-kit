import Foundation

/// Result of validating a state machine's transition table
public struct TransitionValidation<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// Transitions with duplicate (from, event) pairs
    public let duplicates: [(from: State?, event: Event)]

    /// States that appear as targets but have no outgoing transitions
    public let terminalStates: Set<State>

    /// Whether the transition table is valid (no duplicates)
    public var isValid: Bool { duplicates.isEmpty }
}

extension StateMachine {
    /// Validate the transition table for duplicates and terminal states
    public func validate() -> TransitionValidation<State, Event> {
        // Find duplicates: same (from, event) without guards
        var seen: [(State?, Event)] = []
        var duplicates: [(from: State?, event: Event)] = []

        for transition in transitions {
            if transition.guardCondition == nil {
                let key = (transition.from, transition.event)
                if seen.contains(where: { $0.0 == key.0 && $0.1 == key.1 }) {
                    duplicates.append((from: transition.from, event: transition.event))
                } else {
                    seen.append(key)
                }
            }
        }

        // Find terminal states: appear as `to` but never as `from`
        let allTargets = Set(transitions.map(\.to))
        let allSources = Set(transitions.compactMap(\.from))
        let terminalStates = allTargets.subtracting(allSources)

        return TransitionValidation(
            duplicates: duplicates,
            terminalStates: terminalStates
        )
    }
}

import Foundation

/// Result of validating a state machine's transition table
public struct TransitionValidation<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// Transitions with duplicate (from, event) pairs
    public let duplicates: [(from: State?, event: Event)]

    /// States that appear as targets but have no outgoing transitions
    public let terminalStates: Set<State>

    /// States named in the transition table that cannot be reached from the initial state
    ///
    /// Informational only — an unreachable state does not make the table invalid. It usually
    /// means a transition targets a state that nothing ever leads to, or that a source state
    /// was named in the table but wired up from nowhere.
    public let unreachableStates: Set<State>

    /// Whether the transition table is valid (no duplicates)
    public var isValid: Bool { duplicates.isEmpty }
}

extension StateMachine {
    /// Validate the transition table for duplicates, terminal states, and unreachable states
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

        let known = allSources.union(allTargets).union([initialState])
        let unreachableStates = known.subtracting(reachableStates())

        return TransitionValidation(
            duplicates: duplicates,
            terminalStates: terminalStates,
            unreachableStates: unreachableStates
        )
    }

    /// Every state reachable from the initial state by following transitions
    ///
    /// A wildcard transition fires from any state, so its target is always reachable.
    private func reachableStates() -> Set<State> {
        var reachable: Set<State> = [initialState]
        var frontier: [State] = [initialState]

        for transition in transitions where transition.from == nil {
            if reachable.insert(transition.to).inserted {
                frontier.append(transition.to)
            }
        }

        while let state = frontier.popLast() {
            for transition in transitions where transition.from == state {
                if reachable.insert(transition.to).inserted {
                    frontier.append(transition.to)
                }
            }
        }

        return reachable
    }
}

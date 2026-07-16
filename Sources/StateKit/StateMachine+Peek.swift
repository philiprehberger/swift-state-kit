import Foundation

extension StateMachine {
    /// Resolve the destination state an event would produce, without performing the transition
    ///
    /// Uses the same candidate ordering (specific transitions before wildcards) and guard
    /// evaluation as ``send(_:)``, but does **not** mutate state, run side effects,
    /// middleware, or entry/exit actions, record history, or emit stream events.
    ///
    /// Unlike ``canSend(_:)`` — which ignores guard conditions and returns only a `Bool` —
    /// `peek` honors guards and returns the actual target state, making it suitable for
    /// previewing the next state or validating a proposed event before committing to it.
    ///
    /// - Parameter event: The event to evaluate
    /// - Returns: The state the machine would move to, or `nil` if no transition applies
    public func peek(_ event: Event) async -> State? {
        let specific = transitions.filter { $0.from == currentState && $0.event == event }
        let wildcards = transitions.filter { $0.from == nil && $0.event == event }

        for candidate in specific + wildcards {
            if let guardCondition = candidate.guardCondition {
                if await guardCondition() {
                    return candidate.to
                }
            } else {
                return candidate.to
            }
        }
        return nil
    }
}

import Foundation

/// Type-erased wrapper for child state machines
public final class AnyChildMachine: @unchecked Sendable {
    private let _reset: @Sendable () async throws -> Void

    init<S: Hashable & Sendable, E: Hashable & Sendable>(machine: StateMachine<S, E>) {
        self._reset = { try await machine.reset() }
    }

    func reset() async throws {
        try await _reset()
    }
}

extension StateMachine {
    /// Attach a child state machine to a parent state
    ///
    /// When the parent enters this state, the child's transitions become active.
    /// When the parent exits this state, the child is reset.
    public func attach<CS: Hashable & Sendable, CE: Hashable & Sendable>(
        child: StateMachine<CS, CE>,
        to state: State
    ) {
        let wrapper = AnyChildMachine(machine: child)

        onEnter(state) {
            try await child.reset()
        }

        onExit(state) {
            try await wrapper.reset()
        }
    }
}

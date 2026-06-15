import Foundation

extension StateMachine {
    /// Suspend until the machine reaches the given state
    ///
    /// Returns immediately if the machine is already in `state`. Otherwise subscribes
    /// to `stateStream` and resumes when a matching transition occurs.
    ///
    /// - Parameters:
    ///   - state: The target state to wait for
    ///   - timeout: Optional duration after which the call throws `StateMachineError.waitTimeout`
    /// - Returns: The matching state value
    /// - Throws: `StateMachineError.waitTimeout` if the timeout expires,
    ///           `StateMachineError.waitForCancelled` if the stream finishes without matching
    @discardableResult
    public func waitFor(_ state: State, timeout: Duration? = nil) async throws -> State {
        if currentState == state {
            return currentState
        }

        let stream = stateStream
        let target = state

        guard let timeout else {
            for await newState in stream where newState == target {
                return newState
            }
            throw StateMachineError.waitForCancelled
        }

        return try await withThrowingTaskGroup(of: State.self) { group in
            group.addTask {
                for await newState in stream where newState == target {
                    return newState
                }
                throw StateMachineError.waitForCancelled
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw StateMachineError.waitTimeout(state: String(describing: target))
            }
            // swiftlint:disable:next force_unwrapping
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

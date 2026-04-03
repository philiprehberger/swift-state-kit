import Testing
@testable import StateKit

final class ExecutionTracker: @unchecked Sendable {
    var executed = false
}

@Suite("Async Transition Tests")
struct AsyncTransitionTests {
    @Test("Side effect executes during transition")
    func sideEffectExecutes() async throws {
        let tracker = ExecutionTracker()
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading) {
                tracker.executed = true
            }
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        try await machine.send(.start)
        #expect(tracker.executed == true)
    }

    @Test("Failed side effect throws sideEffectFailed")
    func sideEffectFailure() async {
        struct TestError: Error {}
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading) {
                throw TestError()
            }
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        do {
            try await machine.send(.start)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
        }
    }

    @Test("State does not change if side effect fails")
    func stateUnchangedOnFailure() async {
        struct TestError: Error {}
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading) {
                throw TestError()
            }
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        _ = try? await machine.send(.start)
        let state = await machine.currentState
        #expect(state == .idle)
    }
}

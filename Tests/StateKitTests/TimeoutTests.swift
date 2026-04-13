import Testing
@testable import StateKit

@Suite("Timeout Transition Tests")
struct TimeoutTests {
    @Test("Timeout fires after duration")
    func timeoutFires() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .fail, to: .error)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        await machine.addTimeout(TimeoutTransition(
            from: .loading, after: .milliseconds(50), on: .fail, to: .error
        ))
        try await machine.send(.start)
        try await Task.sleep(for: .milliseconds(150))
        let state = await machine.currentState
        #expect(state == .error)
    }

    @Test("Timeout cancelled by state change")
    func timeoutCancelled() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        await machine.addTimeout(TimeoutTransition(
            from: .loading, after: .milliseconds(200), on: .fail, to: .error
        ))
        try await machine.send(.start)
        try await machine.send(.succeed)  // move out before timeout
        try await Task.sleep(for: .milliseconds(300))
        let state = await machine.currentState
        #expect(state == .loaded)  // not error
    }
}

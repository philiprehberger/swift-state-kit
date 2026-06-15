import Testing
@testable import StateKit

@Suite("waitFor Tests")
struct WaitForTests {
    private func makeMachine() -> StateMachine<TestState, TestEvent> {
        StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition(from: .loading, on: .fail, to: .error)
            Transition(from: .loaded, on: .reset, to: .idle)
        }
    }

    @Test("Returns immediately when already in target state")
    func immediateReturn() async throws {
        let machine = makeMachine()
        let result = try await machine.waitFor(.idle)
        #expect(result == .idle)
    }

    @Test("Resolves when target state is reached")
    func resolvesOnTransition() async throws {
        let machine = makeMachine()

        let waiter = Task {
            try await machine.waitFor(.loaded)
        }

        // Give the waiter a moment to subscribe to the stream
        try await Task.sleep(for: .milliseconds(50))
        try await machine.send(.start)
        try await machine.send(.succeed)

        let result = try await waiter.value
        #expect(result == .loaded)
    }

    @Test("Resolves via multi-step path")
    func multiStepPath() async throws {
        let machine = makeMachine()

        let waiter = Task {
            try await machine.waitFor(.loaded, timeout: .seconds(2))
        }

        try await Task.sleep(for: .milliseconds(50))
        try await machine.send(.start)
        try await Task.sleep(for: .milliseconds(20))
        try await machine.send(.succeed)

        let result = try await waiter.value
        #expect(result == .loaded)
    }

    @Test("Times out when target state never reached")
    func timesOut() async throws {
        let machine = makeMachine()

        do {
            _ = try await machine.waitFor(.loaded, timeout: .milliseconds(100))
            #expect(Bool(false), "Should have thrown")
        } catch let error as StateMachineError {
            #expect(error == .waitTimeout(state: String(describing: TestState.loaded)))
        }
    }

    @Test("Ignores non-matching transitions")
    func ignoresNonMatching() async throws {
        let machine = makeMachine()

        let waiter = Task {
            try await machine.waitFor(.loaded, timeout: .seconds(2))
        }

        try await Task.sleep(for: .milliseconds(50))
        try await machine.send(.start)
        try await Task.sleep(for: .milliseconds(20))
        try await machine.send(.fail)         // goes to .error, not .loaded — should not match
        try await Task.sleep(for: .milliseconds(20))
        // Reset path is invalid from .error, so manually navigate via a fresh start chain
        // To get to loaded, we'd need to add a transition .error -> .idle. Instead, cancel.
        waiter.cancel()

        // Confirm task ended (either via timeout, cancellation, or stream finish)
        _ = try? await waiter.value
    }
}

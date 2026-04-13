import Testing
@testable import StateKit

@Suite("Reset Tests")
struct ResetTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("Reset returns to initial state")
    func resetToInitial() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        try await machine.send(.succeed)
        let state = try await machine.reset()
        #expect(state == .idle)
    }

    @Test("Reset clears history")
    func resetClearsHistory() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        try await machine.send(.start)
        try await machine.reset()
        let history = await machine.history
        #expect(history.isEmpty)
    }

    @Test("Reset fires exit and entry actions")
    func resetActions() async throws {
        let log = ActionLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.onExit(.loading) { log.log.append("exit-loading") }
        await machine.onEnter(.idle) { log.log.append("enter-idle") }
        try await machine.send(.start)
        try await machine.reset()
        #expect(log.log.contains("exit-loading"))
        #expect(log.log.contains("enter-idle"))
    }

    @Test("Reset from initial state is a no-op")
    func resetFromInitial() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let state = try await machine.reset()
        #expect(state == .idle)
    }
}

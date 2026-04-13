import Testing
@testable import StateKit

final class ActionLog: @unchecked Sendable {
    var log: [String] = []
}

@Suite("Entry/Exit Action Tests")
struct EntryExitTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("Entry action fires when entering state")
    func entryFires() async throws {
        let log = ActionLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.onEnter(.loading) { log.log.append("enter-loading") }
        try await machine.send(.start)
        #expect(log.log == ["enter-loading"])
    }

    @Test("Exit action fires when leaving state")
    func exitFires() async throws {
        let log = ActionLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.onExit(.idle) { log.log.append("exit-idle") }
        try await machine.send(.start)
        #expect(log.log == ["exit-idle"])
    }

    @Test("Both entry and exit fire on transition")
    func bothFire() async throws {
        let log = ActionLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.onExit(.idle) { log.log.append("exit-idle") }
        await machine.onEnter(.loading) { log.log.append("enter-loading") }
        try await machine.send(.start)
        #expect(log.log == ["exit-idle", "enter-loading"])
    }

    @Test("Entry action not called for non-matching state")
    func entryNoMatch() async throws {
        let log = ActionLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.onEnter(.loaded) { log.log.append("enter-loaded") }
        try await machine.send(.start)
        #expect(log.log.isEmpty)
    }
}

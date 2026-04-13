import Testing
@testable import StateKit

@Suite("State History Tests")
struct HistoryTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .error, on: .reset, to: .idle),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("History records transitions")
    func historyRecords() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        try await machine.send(.start)
        try await machine.send(.succeed)
        let history = await machine.history
        #expect(history.count == 2)
        #expect(history[0].from == .idle)
        #expect(history[0].event == .start)
        #expect(history[0].to == .loading)
        #expect(history[1].from == .loading)
        #expect(history[1].event == .succeed)
        #expect(history[1].to == .loaded)
    }

    @Test("History disabled by default")
    func historyDisabledByDefault() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let history = await machine.history
        #expect(history.isEmpty)
    }

    @Test("Undo restores previous state")
    func undoRestores() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        try await machine.send(.start)
        let restored = try await machine.undo()
        #expect(restored == .idle)
        let current = await machine.currentState
        #expect(current == .idle)
    }

    @Test("Undo multiple steps")
    func undoMultiple() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        try await machine.send(.start)
        try await machine.send(.succeed)
        try await machine.undo()
        let state = try await machine.undo()
        #expect(state == .idle)
    }

    @Test("Undo with no history throws")
    func undoNoHistory() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        do {
            _ = try await machine.undo()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
        }
    }

    @Test("Max depth truncates old entries")
    func maxDepthTruncates() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 2)
        try await machine.send(.start)
        try await machine.send(.succeed)
        try await machine.send(.reset)
        let history = await machine.history
        #expect(history.count == 2)
        #expect(history[0].from == .loading)
    }

    @Test("canUndo reflects history state")
    func canUndoCheck() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        let before = await machine.canUndo
        #expect(before == false)
        try await machine.send(.start)
        let after = await machine.canUndo
        #expect(after == true)
    }
}

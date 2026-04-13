import Testing
@testable import StateKit

@Suite("Valid Events Tests")
struct ValidEventsTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("validEvents returns events for current state")
    func validEventsForCurrent() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let events = await machine.validEvents
        #expect(events == [.start])
    }

    @Test("validEvents for loading state")
    func validEventsForLoading() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let events = await machine.validEvents
        #expect(events == [.succeed, .fail])
    }

    @Test("validEvents empty for terminal state")
    func validEventsTerminal() async {
        let machine = StateMachine(initial: TestState.error, transitions: makeTransitions())
        let events = await machine.validEvents
        #expect(events.isEmpty)
    }

    @Test("validEvents(for:) queries arbitrary state")
    func validEventsForState() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let events = await machine.validEvents(for: .loading)
        #expect(events == [.succeed, .fail])
    }
}

import Testing
@testable import StateKit

@Suite("Transition Validation Tests")
struct ValidationTests {
    @Test("Detects duplicate transitions")
    func detectDuplicates() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .idle, on: .start, to: .error)  // duplicate
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(!result.isValid)
        #expect(result.duplicates.count == 1)
    }

    @Test("No duplicates when guards are used")
    func noDuplicatesWithGuards() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading, guard: { true }),
            Transition(from: .idle, on: .start, to: .error, guard: { false })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.isValid)
    }

    @Test("Detects terminal states")
    func detectTerminalStates() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.terminalStates.contains(.loaded))
    }

    @Test("Valid table returns isValid true")
    func validTable() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.isValid)
    }
}

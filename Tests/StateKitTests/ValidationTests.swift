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

    @Test("Detects unreachable states")
    func detectUnreachableStates() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            // .error can never be entered — nothing transitions to it
            Transition(from: .error, on: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.unreachableStates == [.error])
        // Unreachable states are informational, not a validity failure
        #expect(result.isValid)
    }

    @Test("Fully connected table has no unreachable states")
    func noUnreachableStates() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.unreachableStates.isEmpty)
    }

    @Test("Wildcard targets are always reachable")
    func wildcardTargetsReachable() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(fromAny: .fail, to: .error)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = await machine.validate()
        #expect(result.unreachableStates.isEmpty)
    }
}

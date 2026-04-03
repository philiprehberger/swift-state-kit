import Testing
@testable import StateKit

enum TestState: Hashable, Sendable {
    case idle, loading, loaded, error
}

enum TestEvent: Hashable, Sendable {
    case start, succeed, fail, reset
}

@Suite("StateMachine Tests")
struct StateMachineTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .error, on: .reset, to: .idle),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("Starts in initial state")
    func initialState() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let state = await machine.currentState
        #expect(state == .idle)
    }

    @Test("Valid transition changes state")
    func validTransition() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let newState = try await machine.send(.start)
        #expect(newState == .loading)
    }

    @Test("Invalid transition throws error")
    func invalidTransition() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        do {
            _ = try await machine.send(.succeed)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
        }
    }

    @Test("canSend returns true for valid event")
    func canSendValid() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let result = await machine.canSend(.start)
        #expect(result == true)
    }

    @Test("canSend returns false for invalid event")
    func canSendInvalid() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let result = await machine.canSend(.succeed)
        #expect(result == false)
    }

    @Test("Chain of transitions works")
    func chainedTransitions() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        try await machine.send(.succeed)
        let state = await machine.currentState
        #expect(state == .loaded)
    }

    @Test("onTransition callback is invoked")
    func transitionCallback() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        var captured: (TestState, TestEvent, TestState)?
        await machine.onTransition { from, event, to in
            captured = (from, event, to)
        }
        try await machine.send(.start)
        #expect(captured?.0 == .idle)
        #expect(captured?.1 == .start)
        #expect(captured?.2 == .loading)
    }
}

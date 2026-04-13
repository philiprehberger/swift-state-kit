import Testing
@testable import StateKit

@Suite("Wildcard Transition Tests")
struct WildcardTests {
    @Test("Wildcard fires from any state")
    func wildcardFromAny() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(fromAny: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        try await machine.send(.start)
        let state = try await machine.send(.reset)
        #expect(state == .idle)
    }

    @Test("Specific transition takes priority over wildcard")
    func specificPriority() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .reset, to: .error),  // specific
            Transition(fromAny: .reset, to: .idle)  // wildcard
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        try await machine.send(.start)
        let state = try await machine.send(.reset)
        #expect(state == .error)  // specific wins
    }

    @Test("Wildcard with canSend")
    func wildcardCanSend() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(fromAny: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.loading, transitions: transitions)
        let result = await machine.canSend(.reset)
        #expect(result == true)
    }

    @Test("Wildcard debugDescription shows asterisk")
    func wildcardDebug() {
        let t = Transition<TestState, TestEvent>(fromAny: .reset, to: .idle)
        #expect(t.debugDescription == "Transition(* --reset--> idle)")
    }
}

import Testing
@testable import StateKit

@Suite("State Stream Tests")
struct StreamTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("State stream emits new states")
    func stateStreamEmits() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let stream = await machine.stateStream
        var collected: [TestState] = []

        try await machine.send(.start)
        try await machine.send(.succeed)

        // Collect from stream with a timeout
        for await state in stream {
            collected.append(state)
            if collected.count == 2 { break }
        }

        #expect(collected == [.loading, .loaded])
    }

    @Test("Transition stream emits full tuples")
    func transitionStreamEmits() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let stream = await machine.transitionStream

        try await machine.send(.start)

        for await transition in stream {
            #expect(transition.from == .idle)
            #expect(transition.event == .start)
            #expect(transition.to == .loading)
            break
        }
    }
}

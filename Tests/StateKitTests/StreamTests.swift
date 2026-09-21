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

    @Test("Reset emits the initial state on the state stream")
    func resetEmitsOnStateStream() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let stream = await machine.stateStream
        var collected: [TestState] = []

        try await machine.send(.start)
        try await machine.reset()

        for await state in stream {
            collected.append(state)
            if collected.count == 2 { break }
        }

        #expect(collected == [.loading, .idle])
    }

    @Test("Reset while already in the initial state emits nothing")
    func resetInInitialStateEmitsNothing() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let stream = await machine.stateStream
        var collected: [TestState] = []

        try await machine.reset()
        try await machine.send(.start)

        for await state in stream {
            collected.append(state)
            if collected.count == 1 { break }
        }

        #expect(collected == [.loading])
    }

    @Test("Undo emits the restored state on the state stream")
    func undoEmitsOnStateStream() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        let stream = await machine.stateStream
        var collected: [TestState] = []

        try await machine.send(.start)
        try await machine.undo()

        for await state in stream {
            collected.append(state)
            if collected.count == 2 { break }
        }

        #expect(collected == [.loading, .idle])
    }

    @Test("Undo does not emit on the transition stream")
    func undoDoesNotEmitTransition() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        let stream = await machine.transitionStream
        var collected: [TestEvent] = []

        try await machine.send(.start)
        try await machine.undo()
        try await machine.send(.start)

        for await (_, event, _) in stream {
            collected.append(event)
            if collected.count == 2 { break }
        }

        // Only the two sends produced transitions; the undo between them did not
        #expect(collected == [.start, .start])
    }
}

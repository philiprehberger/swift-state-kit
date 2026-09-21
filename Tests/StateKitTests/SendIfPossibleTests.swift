import Testing
@testable import StateKit

@Suite("sendIfPossible Tests")
struct SendIfPossibleTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded)
        ]
    }

    @Test("Returns the new state when a transition applies")
    func returnsNewState() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let result = try await machine.sendIfPossible(.start)
        #expect(result == .loading)
        #expect(await machine.currentState == .loading)
    }

    @Test("Returns nil instead of throwing when no transition applies")
    func returnsNilForInvalidEvent() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let result = try await machine.sendIfPossible(.succeed)
        #expect(result == nil)
        #expect(await machine.currentState == .idle)
    }

    @Test("Does not record history for an inapplicable event")
    func noHistoryForInvalidEvent() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        _ = try await machine.sendIfPossible(.succeed)
        #expect(await machine.history.isEmpty)
        #expect(await machine.canUndo == false)
    }

    @Test("Runs side effects when the transition applies")
    func runsSideEffect() async throws {
        let flag = TransitionCapture()
        let transitions = [
            Transition(from: TestState.idle, on: TestEvent.start, to: .loading, sideEffect: {
                flag.value = (.idle, .start, .loading)
            })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        _ = try await machine.sendIfPossible(.start)
        #expect(flag.value != nil)
    }

    @Test("Side effect failures still throw")
    func sideEffectFailurePropagates() async throws {
        struct Boom: Error {}
        let transitions = [
            Transition(from: TestState.idle, on: TestEvent.start, to: .loading, sideEffect: {
                throw Boom()
            })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)

        await #expect(throws: StateMachineError.self) {
            _ = try await machine.sendIfPossible(.start)
        }
        #expect(await machine.currentState == .idle)
    }

    @Test("Honors guard conditions, returning nil when every guard fails")
    func honorsGuards() async throws {
        let transitions = [
            Transition(from: TestState.idle, on: TestEvent.start, to: .loading, guard: { false })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let result = try await machine.sendIfPossible(.start)
        #expect(result == nil)
        #expect(await machine.currentState == .idle)
    }
}

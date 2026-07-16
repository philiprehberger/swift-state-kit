import Testing
@testable import StateKit

@Suite("peek Tests")
struct PeekTests {
    private func makeMachine() -> StateMachine<TestState, TestEvent> {
        StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition(from: .loading, on: .fail, to: .error)
            Transition(fromAny: .reset, to: .idle)
        }
    }

    @Test("Returns the destination state for a valid event")
    func returnsDestination() async {
        let machine = makeMachine()
        let target = await machine.peek(.start)
        #expect(target == .loading)
    }

    @Test("Returns nil for an invalid event")
    func returnsNilForInvalid() async {
        let machine = makeMachine()
        let target = await machine.peek(.succeed)
        #expect(target == nil)
    }

    @Test("Resolves wildcard transitions")
    func resolvesWildcard() async {
        let machine = makeMachine()
        let target = await machine.peek(.reset)
        #expect(target == .idle)
    }

    @Test("Does not mutate current state or history")
    func doesNotMutate() async throws {
        let machine = makeMachine()
        _ = await machine.peek(.start)
        let state = await machine.currentState
        let history = await machine.history
        #expect(state == .idle)
        #expect(history.isEmpty)
    }

    @Test("Honors guard conditions")
    func honorsGuards() async {
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading, guard: { false })
            Transition(from: .idle, on: .start, to: .error, guard: { true })
        }
        let target = await machine.peek(.start)
        #expect(target == .error)
    }

    @Test("Returns nil when all guards fail")
    func nilWhenAllGuardsFail() async {
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading, guard: { false })
        }
        let target = await machine.peek(.start)
        #expect(target == nil)
    }
}

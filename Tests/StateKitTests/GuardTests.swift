import Testing
@testable import StateKit

@Suite("Guard Condition Tests")
struct GuardTests {
    @Test("Guard passing allows transition")
    func guardPasses() async throws {
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading, guard: { true })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let state = try await machine.send(.start)
        #expect(state == .loading)
    }

    @Test("Guard failing skips transition")
    func guardFails() async {
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading, guard: { false })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        do {
            _ = try await machine.send(.start)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
        }
    }

    @Test("Guard failing falls through to next matching transition")
    func guardFallthrough() async throws {
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading, guard: { false }),
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .error, guard: { true })
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let state = try await machine.send(.start)
        #expect(state == .error)
    }

    @Test("No guard means transition always taken")
    func noGuard() async throws {
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let state = try await machine.send(.start)
        #expect(state == .loading)
    }
}

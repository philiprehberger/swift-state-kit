import Testing
@testable import StateKit

@Suite("Batch send Tests")
struct BatchSendTests {
    private func makeMachine() -> StateMachine<TestState, TestEvent> {
        StateMachine<TestState, TestEvent>(initial: .idle, historyDepth: 0) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition(from: .loaded, on: .reset, to: .idle)
        }
    }

    @Test("Applies a sequence of events and returns the final state")
    func appliesSequence() async throws {
        let machine = makeMachine()
        let final = try await machine.send([.start, .succeed, .reset])
        #expect(final == .idle)
    }

    @Test("Empty sequence returns the current state unchanged")
    func emptySequence() async throws {
        let machine = makeMachine()
        let final = try await machine.send([])
        #expect(final == .idle)
        let state = await machine.currentState
        #expect(state == .idle)
    }

    @Test("Throws on the first invalid event")
    func throwsOnInvalid() async {
        let machine = makeMachine()
        await #expect(throws: StateMachineError.self) {
            try await machine.send([.start, .reset])
        }
    }

    @Test("Events before the failure remain committed")
    func partialApplication() async {
        let machine = makeMachine()
        _ = try? await machine.send([.start, .reset])
        let state = await machine.currentState
        #expect(state == .loading)
    }
}

import Testing
@testable import StateKit

@Suite("Transition Builder Tests")
struct TransitionBuilderTests {
    @Test("Builder init creates working machine")
    func builderInit() async throws {
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition(from: .loaded, on: .reset, to: .idle)
        }

        try await machine.send(.start)
        try await machine.send(.succeed)
        let state = await machine.currentState
        #expect(state == .loaded)
    }

    @Test("Builder supports multi-source helper")
    func multiSourceHelper() async throws {
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition.from([.loading, .loaded], on: .reset, to: .idle)
        }

        try await machine.send(.start)
        let s1 = try await machine.send(.reset)
        #expect(s1 == .idle)

        try await machine.send(.start)
        try await machine.send(.succeed)
        let s2 = try await machine.send(.reset)
        #expect(s2 == .idle)
    }

    @Test("Builder supports optional blocks")
    func optionalBlocks() async throws {
        let includeReset = true
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            if includeReset {
                Transition(from: .loaded, on: .reset, to: .idle)
            }
        }

        try await machine.send(.start)
        try await machine.send(.succeed)
        let state = try await machine.send(.reset)
        #expect(state == .idle)
    }

    @Test("Builder supports for loops")
    func forLoopBuilder() async throws {
        let resetSources: [TestState] = [.loading, .loaded, .error]
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            Transition(from: .loading, on: .succeed, to: .loaded)
            Transition(from: .loading, on: .fail, to: .error)
            for source in resetSources {
                Transition(from: source, on: .reset, to: .idle)
            }
        }

        try await machine.send(.start)
        try await machine.send(.fail)
        let state = try await machine.send(.reset)
        #expect(state == .idle)
    }

    @Test("Builder supports if/else branches")
    func eitherBranches() async throws {
        let useFail = false
        let machine = StateMachine<TestState, TestEvent>(initial: .idle) {
            Transition(from: .idle, on: .start, to: .loading)
            if useFail {
                Transition(from: .loading, on: .succeed, to: .error)
            } else {
                Transition(from: .loading, on: .succeed, to: .loaded)
            }
        }

        try await machine.send(.start)
        let state = try await machine.send(.succeed)
        #expect(state == .loaded)
    }

    @Test("from() helper produces one transition per source")
    func fromHelperCount() {
        let transitions = Transition<TestState, TestEvent>.from(
            [.idle, .loading, .loaded],
            on: .reset,
            to: .idle
        )
        #expect(transitions.count == 3)
        #expect(transitions[0].from == .idle)
        #expect(transitions[1].from == .loading)
        #expect(transitions[2].from == .loaded)
        #expect(transitions.allSatisfy { $0.event == .reset && $0.to == .idle })
    }
}

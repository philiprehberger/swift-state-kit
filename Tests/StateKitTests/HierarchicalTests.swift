import Testing
@testable import StateKit

enum ChildState: Hashable, Sendable {
    case ready, running, done
}

enum ChildEvent: Hashable, Sendable {
    case go, finish, childReset
}

@Suite("Hierarchical State Machine Tests")
struct HierarchicalTests {
    @Test("Child resets when parent enters state")
    func childResetsOnEntry() async throws {
        let childTransitions: [Transition<ChildState, ChildEvent>] = [
            Transition(from: .ready, on: .go, to: .running),
            Transition(from: .running, on: .finish, to: .done)
        ]
        let child = StateMachine(initial: ChildState.ready, transitions: childTransitions)

        let parentTransitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
        let parent = StateMachine(initial: TestState.idle, transitions: parentTransitions)

        await parent.attach(child: child, to: .loading)

        // Move child to a non-initial state
        try await child.send(.go)
        let childState1 = await child.currentState
        #expect(childState1 == .running)

        // Enter loading — child should reset
        try await parent.send(.start)
        let childState2 = await child.currentState
        #expect(childState2 == .ready)
    }

    @Test("Child resets when parent exits state")
    func childResetsOnExit() async throws {
        let childTransitions: [Transition<ChildState, ChildEvent>] = [
            Transition(from: .ready, on: .go, to: .running)
        ]
        let child = StateMachine(initial: ChildState.ready, transitions: childTransitions)

        let parentTransitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded)
        ]
        let parent = StateMachine(initial: TestState.idle, transitions: parentTransitions)

        await parent.attach(child: child, to: .loading)

        // Enter loading, advance child
        try await parent.send(.start)
        try await child.send(.go)
        let childState1 = await child.currentState
        #expect(childState1 == .running)

        // Exit loading — child should reset
        try await parent.send(.succeed)
        let childState2 = await child.currentState
        #expect(childState2 == .ready)
    }
}

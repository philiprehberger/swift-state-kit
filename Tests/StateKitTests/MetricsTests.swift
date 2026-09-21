import Testing
@testable import StateKit

@Suite("Transition Metrics Tests")
struct MetricsTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("Metrics count transitions")
    func metricsCount() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), enableMetrics: true)
        try await machine.send(.start)
        try await machine.send(.succeed)
        let metrics = await machine.metrics
        #expect(metrics?.totalTransitions == 2)
        #expect(metrics?.transitionCount(from: .idle, on: .start) == 1)
    }

    @Test("Metrics disabled by default")
    func metricsDisabled() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let metrics = await machine.metrics
        #expect(metrics == nil)
    }

    @Test("Reset clears metrics")
    func resetMetrics() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), enableMetrics: true)
        try await machine.send(.start)
        await machine.resetMetrics()
        let metrics = await machine.metrics
        #expect(metrics?.totalTransitions == 0)
    }

    @Test("Event count aggregates across source states")
    func eventCountAggregates() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .error, on: .reset, to: .idle),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions, enableMetrics: true)
        try await machine.send(.start)
        try await machine.send(.fail)
        try await machine.send(.reset)
        try await machine.send(.start)

        let metrics = await machine.metrics
        #expect(metrics?.eventCount(.start) == 2)
        #expect(metrics?.eventCount(.fail) == 1)
        #expect(metrics?.eventCount(.succeed) == 0)
    }

    @Test("All transition counts are enumerable, most frequent first")
    func allTransitionCounts() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions, enableMetrics: true)
        try await machine.send(.start)
        try await machine.send(.succeed)
        try await machine.send(.reset)
        try await machine.send(.start)

        let counts = await machine.metrics?.allTransitionCounts
        #expect(counts?.count == 3)
        #expect(counts?.first?.from == .idle)
        #expect(counts?.first?.event == .start)
        #expect(counts?.first?.count == 2)

        let top = await machine.metrics?.mostFrequentTransition
        #expect(top?.count == 2)
    }

    @Test("Most frequent transition is nil before any transition")
    func mostFrequentEmpty() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), enableMetrics: true)
        let top = await machine.metrics?.mostFrequentTransition
        #expect(top == nil)
    }

    @Test("Time in the current state includes the visit in progress")
    func timeInCurrentState() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), enableMetrics: true)
        try await machine.send(.start)
        try await Task.sleep(for: .milliseconds(60))

        let metrics = await machine.metrics
        // .loading is the state currently occupied — its in-progress visit must be counted
        #expect((metrics?.timeInState(.loading) ?? 0) > 0.03)
        // .idle was left, so it reports only its closed interval
        #expect((metrics?.timeInState(.idle) ?? 0) > 0)
    }

    @Test("Distinct states are not conflated by transition keys")
    func distinctTransitionKeys() async throws {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .error, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions, enableMetrics: true)
        try await machine.send(.start)
        try await machine.send(.fail)
        try await machine.send(.start)

        let metrics = await machine.metrics
        #expect(metrics?.transitionCount(from: .idle, on: .start) == 1)
        #expect(metrics?.transitionCount(from: .error, on: .start) == 1)
    }
}

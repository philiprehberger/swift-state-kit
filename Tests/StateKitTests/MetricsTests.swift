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
}

import Testing
@testable import StateKit

@Suite("StateLogger Tests")
struct LoggerTests {
    @Test("Logger receives transition messages")
    func loggerCalled() async throws {
        var messages: [String] = []
        let logger = StateLogger { messages.append($0) }
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions, logger: logger)
        try await machine.send(.start)
        #expect(messages.count == 1)
        #expect(messages[0].contains("idle"))
        #expect(messages[0].contains("loading"))
    }

    @Test("No logger means no logging")
    func noLogger() async throws {
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        // Should not crash
        try await machine.send(.start)
    }
}

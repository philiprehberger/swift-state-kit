import Testing
@testable import StateKit

final class MessageCapture: @unchecked Sendable {
    var messages: [String] = []
}

@Suite("StateLogger Tests")
struct LoggerTests {
    @Test("Logger receives transition messages")
    func loggerCalled() async throws {
        let capture = MessageCapture()
        let logger = StateLogger { capture.messages.append($0) }
        let transitions = [
            Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions, logger: logger)
        try await machine.send(.start)
        #expect(capture.messages.count == 1)
        #expect(capture.messages[0].contains("idle"))
        #expect(capture.messages[0].contains("loading"))
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

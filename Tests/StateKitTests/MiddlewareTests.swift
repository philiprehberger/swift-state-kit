import Testing
@testable import StateKit

final class MiddlewareLog: @unchecked Sendable {
    var entries: [String] = []
}

struct LoggingMiddleware: TransitionMiddleware {
    let log: MiddlewareLog
    let label: String

    func intercept(
        from: TestState,
        event: TestEvent,
        to: TestState,
        next: @Sendable () async throws -> Void
    ) async throws {
        log.entries.append("\(label)-before")
        try await next()
        log.entries.append("\(label)-after")
    }
}

struct RejectingMiddleware: TransitionMiddleware {
    struct Rejected: Error {}

    func intercept(
        from: TestState,
        event: TestEvent,
        to: TestState,
        next: @Sendable () async throws -> Void
    ) async throws {
        throw Rejected()
    }
}

@Suite("Middleware Tests")
struct MiddlewareTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [Transition(from: .idle, on: .start, to: .loading)]
    }

    @Test("Middleware executes around transition")
    func middlewareExecutes() async throws {
        let log = MiddlewareLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.addMiddleware(LoggingMiddleware(log: log, label: "mw"))
        try await machine.send(.start)
        #expect(log.entries == ["mw-before", "mw-after"])
    }

    @Test("Middleware chain ordering")
    func chainOrdering() async throws {
        let log = MiddlewareLog()
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.addMiddleware(LoggingMiddleware(log: log, label: "first"))
        await machine.addMiddleware(LoggingMiddleware(log: log, label: "second"))
        try await machine.send(.start)
        #expect(log.entries == ["first-before", "second-before", "second-after", "first-after"])
    }

    @Test("Middleware can reject transition")
    func middlewareRejects() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        await machine.addMiddleware(RejectingMiddleware())
        do {
            _ = try await machine.send(.start)
            #expect(Bool(false), "Should have thrown")
        } catch {
            let state = await machine.currentState
            #expect(state == .idle)
        }
    }
}

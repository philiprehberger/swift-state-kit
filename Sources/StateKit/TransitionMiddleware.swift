import Foundation

/// A middleware that can inspect, modify, or reject transitions
///
/// Middleware is called in order before a transition executes. Each middleware
/// must call `next()` to proceed, or throw to reject the transition.
public protocol TransitionMiddleware<State, Event>: Sendable {
    associatedtype State: Hashable & Sendable
    associatedtype Event: Hashable & Sendable

    /// Intercept a transition
    ///
    /// - Parameters:
    ///   - from: The current state
    ///   - event: The event being processed
    ///   - to: The target state
    ///   - next: Call this to proceed to the next middleware or execute the transition
    func intercept(
        from: State,
        event: Event,
        to: State,
        next: @Sendable () async throws -> Void
    ) async throws
}

/// Type-erased wrapper for transition middleware
struct AnyTransitionMiddleware<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    private let _intercept: @Sendable (State, Event, State, @Sendable () async throws -> Void) async throws -> Void

    init<M: TransitionMiddleware>(_ middleware: M) where M.State == State, M.Event == Event {
        self._intercept = { from, event, to, next in
            try await middleware.intercept(from: from, event: event, to: to, next: next)
        }
    }

    func intercept(
        from: State,
        event: Event,
        to: State,
        next: @Sendable () async throws -> Void
    ) async throws {
        try await _intercept(from, event, to, next)
    }
}

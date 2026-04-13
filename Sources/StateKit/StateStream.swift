import Foundation

/// Manages AsyncStream continuations for state change broadcasting
struct StateStreamBroadcaster<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    private let stateContinuations: LockedBox<[UUID: AsyncStream<State>.Continuation]>
    private let transitionContinuations: LockedBox<[UUID: AsyncStream<(from: State, event: Event, to: State)>.Continuation]>

    init() {
        self.stateContinuations = LockedBox([:])
        self.transitionContinuations = LockedBox([:])
    }

    func makeStateStream() -> AsyncStream<State> {
        let id = UUID()
        return AsyncStream { continuation in
            stateContinuations.withLock { $0[id] = continuation }
            continuation.onTermination = { @Sendable _ in
                stateContinuations.withLock { _ = $0.removeValue(forKey: id) }
            }
        }
    }

    func makeTransitionStream() -> AsyncStream<(from: State, event: Event, to: State)> {
        let id = UUID()
        return AsyncStream { continuation in
            transitionContinuations.withLock { $0[id] = continuation }
            continuation.onTermination = { @Sendable _ in
                transitionContinuations.withLock { _ = $0.removeValue(forKey: id) }
            }
        }
    }

    func broadcast(from: State, event: Event, to: State) {
        stateContinuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.yield(to)
            }
        }
        transitionContinuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.yield((from: from, event: event, to: to))
            }
        }
    }

    func finishAll() {
        stateContinuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.finish()
            }
            continuations.removeAll()
        }
        transitionContinuations.withLock { continuations in
            for continuation in continuations.values {
                continuation.finish()
            }
            continuations.removeAll()
        }
    }
}

/// A thread-safe box using a lock for synchronization
final class LockedBox<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withLock<T>(_ body: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}

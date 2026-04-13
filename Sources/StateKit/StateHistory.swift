import Foundation

/// A record of a single state transition
public struct StateHistoryEntry<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// The state before the transition
    public let from: State

    /// The event that triggered the transition
    public let event: Event

    /// The state after the transition
    public let to: State

    /// When the transition occurred
    public let timestamp: Date
}

/// Maintains a bounded history of state transitions
struct StateHistory<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    private var entries: [StateHistoryEntry<State, Event>] = []
    private let maxDepth: Int?

    /// Create a history with an optional maximum depth
    ///
    /// - Parameter maxDepth: Maximum number of entries to keep. `nil` disables history, `0` means unlimited.
    init(maxDepth: Int?) {
        self.maxDepth = maxDepth
    }

    /// Whether history tracking is enabled
    var isEnabled: Bool { maxDepth != nil }

    /// All recorded entries, oldest first
    var all: [StateHistoryEntry<State, Event>] { entries }

    /// Whether there are entries to undo
    var canUndo: Bool { !entries.isEmpty }

    /// The most recent entry, if any
    var last: StateHistoryEntry<State, Event>? { entries.last }

    /// Record a transition
    mutating func record(from: State, event: Event, to: State) {
        guard isEnabled else { return }
        let entry = StateHistoryEntry(from: from, event: event, to: to, timestamp: Date())
        entries.append(entry)
        if let maxDepth, maxDepth > 0, entries.count > maxDepth {
            entries.removeFirst(entries.count - maxDepth)
        }
    }

    /// Remove and return the last entry (for undo)
    @discardableResult
    mutating func popLast() -> StateHistoryEntry<State, Event>? {
        entries.popLast()
    }

    /// Remove all entries
    mutating func clear() {
        entries.removeAll()
    }
}

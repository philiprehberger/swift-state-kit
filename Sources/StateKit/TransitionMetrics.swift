import Foundation

/// Tracks transition counts and time spent in each state
public struct TransitionMetrics<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    private var counts: [String: Int] = [:]
    private var stateEntryTimes: [State: Date] = [:]
    private var stateDurations: [State: TimeInterval] = [:]

    /// Total number of transitions
    public var totalTransitions: Int {
        counts.values.reduce(0, +)
    }

    /// Number of times a specific transition has been taken
    public func transitionCount(from: State, on event: Event) -> Int {
        counts["\(from)--\(event)"] ?? 0
    }

    /// Total time spent in a given state
    public func timeInState(_ state: State) -> TimeInterval {
        stateDurations[state] ?? 0
    }

    /// Record a transition
    mutating func record(from: State, event: Event, to: State) {
        let key = "\(from)--\(event)"
        counts[key, default: 0] += 1

        // Close out time for the old state
        if let entryTime = stateEntryTimes[from] {
            stateDurations[from, default: 0] += Date().timeIntervalSince(entryTime)
        }

        // Start timing the new state
        stateEntryTimes[to] = Date()
    }

    /// Reset all metrics
    public mutating func reset() {
        counts.removeAll()
        stateEntryTimes.removeAll()
        stateDurations.removeAll()
    }

    /// Start timing for the initial state
    mutating func startTiming(for state: State) {
        stateEntryTimes[state] = Date()
    }
}

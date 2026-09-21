import Foundation

/// A transition and the number of times it has been taken
public struct TransitionCount<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// The source state
    public let from: State

    /// The triggering event
    public let event: Event

    /// How many times the transition has been recorded
    public let count: Int
}

/// Tracks transition counts and time spent in each state
public struct TransitionMetrics<State: Hashable & Sendable, Event: Hashable & Sendable>: Sendable {
    /// Identifies a transition by its source state and event
    private struct TransitionKey: Hashable, Sendable {
        let from: State
        let event: Event
    }

    private var counts: [TransitionKey: Int] = [:]
    private var stateEntryTimes: [State: Date] = [:]
    private var stateDurations: [State: TimeInterval] = [:]
    private var occupiedState: State?

    /// Total number of transitions
    public var totalTransitions: Int {
        counts.values.reduce(0, +)
    }

    /// Number of times a specific transition has been taken
    public func transitionCount(from: State, on event: Event) -> Int {
        counts[TransitionKey(from: from, event: event)] ?? 0
    }

    /// Number of transitions triggered by an event, from any source state
    public func eventCount(_ event: Event) -> Int {
        counts.reduce(0) { $1.key.event == event ? $0 + $1.value : $0 }
    }

    /// Every recorded transition with its count, most frequent first
    public var allTransitionCounts: [TransitionCount<State, Event>] {
        counts
            .map { TransitionCount(from: $0.key.from, event: $0.key.event, count: $0.value) }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return "\($0.from)--\($0.event)" < "\($1.from)--\($1.event)"
            }
    }

    /// The most frequently taken transition, or `nil` if none have been recorded
    public var mostFrequentTransition: TransitionCount<State, Event>? {
        allTransitionCounts.first
    }

    /// Total time spent in a given state, including the current visit if the machine is in it
    public func timeInState(_ state: State) -> TimeInterval {
        var total = stateDurations[state] ?? 0
        if state == occupiedState, let entryTime = stateEntryTimes[state] {
            total += Date().timeIntervalSince(entryTime)
        }
        return total
    }

    /// Record a transition
    mutating func record(from: State, event: Event, to: State) {
        counts[TransitionKey(from: from, event: event), default: 0] += 1

        // Close out time for the old state
        if let entryTime = stateEntryTimes.removeValue(forKey: from) {
            stateDurations[from, default: 0] += Date().timeIntervalSince(entryTime)
        }

        // Start timing the new state
        stateEntryTimes[to] = Date()
        occupiedState = to
    }

    /// Reset all metrics
    public mutating func reset() {
        counts.removeAll()
        stateEntryTimes.removeAll()
        stateDurations.removeAll()
        occupiedState = nil
    }

    /// Start timing for the initial state
    mutating func startTiming(for state: State) {
        stateEntryTimes[state] = Date()
        occupiedState = state
    }
}

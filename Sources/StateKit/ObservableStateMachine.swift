#if canImport(Observation)
import Foundation
import Observation

/// An observable wrapper around `StateMachine` for use in SwiftUI
///
/// ```swift
/// @State private var machine = ObservableStateMachine(machine: myMachine)
/// Text("State: \(machine.state)")
/// ```
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
@Observable
public final class ObservableStateMachine<State: Hashable & Sendable, Event: Hashable & Sendable>: @unchecked Sendable {
    /// The current state (observable)
    public private(set) var state: State

    /// Whether a transition is currently in progress
    public private(set) var isTransitioning: Bool = false

    private let machine: StateMachine<State, Event>

    /// Create an observable wrapper around a state machine
    public init(machine: StateMachine<State, Event>, initialState: State) {
        self.machine = machine
        self.state = initialState
    }

    /// Send an event to trigger a transition, updating the observable state
    @discardableResult
    public func send(_ event: Event) async throws -> State {
        isTransitioning = true
        defer { isTransitioning = false }
        let newState = try await machine.send(event)
        state = newState
        return newState
    }

    /// Check if an event can be handled in the current state
    public func canSend(_ event: Event) async -> Bool {
        await machine.canSend(event)
    }
}
#endif

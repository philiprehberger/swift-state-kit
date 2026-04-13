import Foundation

/// A type-safe state machine with async transition support
///
/// ```swift
/// let machine = StateMachine(
///     initial: MyState.idle,
///     transitions: [
///         Transition(from: .idle, on: .start, to: .running)
///     ]
/// )
/// let newState = try await machine.send(.start)
/// ```
public actor StateMachine<State: Hashable & Sendable, Event: Hashable & Sendable> {
    /// The current state of the machine
    public private(set) var currentState: State

    /// The initial state the machine was created with
    public let initialState: State

    private let transitions: [Transition<State, Event>]
    private let logger: StateLogger?
    private var handlers: [@Sendable (State, Event, State) -> Void] = []
    private var stateHistory: StateHistory<State, Event>
    private let broadcaster: StateStreamBroadcaster<State, Event>
    private var entryActions: [State: [@Sendable () async throws -> Void]] = [:]
    private var exitActions: [State: [@Sendable () async throws -> Void]] = [:]

    /// The transition history, oldest first
    public var history: [StateHistoryEntry<State, Event>] {
        stateHistory.all
    }

    /// Whether an undo operation is available
    public var canUndo: Bool {
        stateHistory.canUndo
    }

    /// Create a state machine with an initial state and transition definitions
    ///
    /// - Parameters:
    ///   - initial: The starting state
    ///   - transitions: Valid state transitions
    ///   - logger: Optional logger for transition messages
    ///   - historyDepth: Maximum history entries to keep. `nil` disables history, `0` means unlimited.
    public init(
        initial: State,
        transitions: [Transition<State, Event>],
        logger: StateLogger? = nil,
        historyDepth: Int? = nil
    ) {
        self.currentState = initial
        self.initialState = initial
        self.transitions = transitions
        self.logger = logger
        self.stateHistory = StateHistory(maxDepth: historyDepth)
        self.broadcaster = StateStreamBroadcaster()
    }

    /// Send an event to trigger a state transition
    ///
    /// - Returns: The new state after the transition
    /// - Throws: `StateMachineError.invalidTransition` if no matching transition exists,
    ///           `StateMachineError.sideEffectFailed` if the side effect throws
    @discardableResult
    public func send(_ event: Event) async throws -> State {
        // Specific transitions first, then wildcards
        let specific = transitions.filter { $0.from == currentState && $0.event == event }
        let wildcards = transitions.filter { $0.from == nil && $0.event == event }
        let candidates = specific + wildcards

        var matched: Transition<State, Event>?
        for candidate in candidates {
            if let guardCondition = candidate.guardCondition {
                if await guardCondition() {
                    matched = candidate
                    break
                }
            } else {
                matched = candidate
                break
            }
        }

        guard let transition = matched else {
            throw StateMachineError.invalidTransition(
                from: String(describing: currentState),
                event: String(describing: event)
            )
        }

        if let sideEffect = transition.sideEffect {
            do {
                try await sideEffect()
            } catch {
                throw StateMachineError.sideEffectFailed(error)
            }
        }

        let oldState = currentState

        // Execute exit actions for the current state
        if let actions = exitActions[oldState] {
            for action in actions {
                try await action()
            }
        }

        currentState = transition.to

        // Execute entry actions for the new state
        if let actions = entryActions[currentState] {
            for action in actions {
                try await action()
            }
        }

        stateHistory.record(from: oldState, event: event, to: currentState)

        logger?.log("[StateKit] \(oldState) --\(event)--> \(currentState)")

        broadcaster.broadcast(from: oldState, event: event, to: currentState)

        for handler in handlers {
            handler(oldState, event, currentState)
        }

        return currentState
    }

    /// Undo the most recent transition, returning to the previous state
    ///
    /// - Returns: The restored state
    /// - Throws: `StateMachineError.noHistoryToUndo` if there is nothing to undo
    @discardableResult
    public func undo() throws -> State {
        guard let entry = stateHistory.popLast() else {
            throw StateMachineError.noHistoryToUndo
        }
        currentState = entry.from
        logger?.log("[StateKit] undo: \(entry.to) --> \(entry.from)")
        return currentState
    }

    /// An async stream of state values, emitting the new state after each transition
    public var stateStream: AsyncStream<State> {
        broadcaster.makeStateStream()
    }

    /// An async stream of full transition tuples (from, event, to)
    public var transitionStream: AsyncStream<(from: State, event: Event, to: State)> {
        broadcaster.makeTransitionStream()
    }

    /// Check if an event can be handled in the current state
    public func canSend(_ event: Event) -> Bool {
        transitions.contains { $0.matches(state: currentState, event: event) }
    }

    /// Register a callback invoked after each transition
    public func onTransition(_ handler: @escaping @Sendable (State, Event, State) -> Void) {
        handlers.append(handler)
    }

    /// Register an action to execute when entering a state
    public func onEnter(_ state: State, perform action: @escaping @Sendable () async throws -> Void) {
        entryActions[state, default: []].append(action)
    }

    /// Register an action to execute when exiting a state
    public func onExit(_ state: State, perform action: @escaping @Sendable () async throws -> Void) {
        exitActions[state, default: []].append(action)
    }
}

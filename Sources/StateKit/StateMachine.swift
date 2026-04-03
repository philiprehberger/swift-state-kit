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

    private let transitions: [Transition<State, Event>]
    private let logger: StateLogger?
    private var handlers: [@Sendable (State, Event, State) -> Void] = []

    /// Create a state machine with an initial state and transition definitions
    public init(
        initial: State,
        transitions: [Transition<State, Event>],
        logger: StateLogger? = nil
    ) {
        self.currentState = initial
        self.transitions = transitions
        self.logger = logger
    }

    /// Send an event to trigger a state transition
    ///
    /// - Returns: The new state after the transition
    /// - Throws: `StateMachineError.invalidTransition` if no matching transition exists,
    ///           `StateMachineError.sideEffectFailed` if the side effect throws
    @discardableResult
    public func send(_ event: Event) async throws -> State {
        guard let transition = transitions.first(where: { $0.from == currentState && $0.event == event }) else {
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
        currentState = transition.to

        logger?.log("[StateKit] \(oldState) --\(event)--> \(currentState)")

        for handler in handlers {
            handler(oldState, event, currentState)
        }

        return currentState
    }

    /// Check if an event can be handled in the current state
    public func canSend(_ event: Event) -> Bool {
        transitions.contains { $0.from == currentState && $0.event == event }
    }

    /// Register a callback invoked after each transition
    public func onTransition(_ handler: @escaping @Sendable (State, Event, State) -> Void) {
        handlers.append(handler)
    }
}

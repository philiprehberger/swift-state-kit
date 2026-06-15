import Foundation

/// A result builder for declarative state machine transition tables
///
/// ```swift
/// let machine = StateMachine<OrderState, OrderEvent>(initial: .pending) {
///     Transition(from: .pending,   on: .confirm, to: .confirmed)
///     Transition(from: .confirmed, on: .ship,    to: .shipped)
///     Transition.from([.confirmed, .shipped], on: .cancel, to: .cancelled)
/// }
/// ```
@resultBuilder
public enum TransitionBuilder<State: Hashable & Sendable, Event: Hashable & Sendable> {
    public typealias Component = [Transition<State, Event>]

    public static func buildExpression(_ expression: Transition<State, Event>) -> Component {
        [expression]
    }

    public static func buildExpression(_ expression: Component) -> Component {
        expression
    }

    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: Component?) -> Component {
        component ?? []
    }

    public static func buildEither(first component: Component) -> Component {
        component
    }

    public static func buildEither(second component: Component) -> Component {
        component
    }

    public static func buildArray(_ components: [Component]) -> Component {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: Component) -> Component {
        component
    }
}

extension Transition {
    /// Expand a list of source states into individual transitions sharing the same event and target
    ///
    /// ```swift
    /// Transition.from([.confirmed, .shipped], on: .cancel, to: .cancelled)
    /// ```
    ///
    /// Composes naturally inside `@TransitionBuilder` blocks or array literals.
    public static func from(
        _ states: [State],
        on event: Event,
        to: State,
        guard condition: (@Sendable () async -> Bool)? = nil,
        sideEffect: (@Sendable () async throws -> Void)? = nil
    ) -> [Transition<State, Event>] {
        states.map {
            Transition(from: $0, on: event, to: to, guard: condition, sideEffect: sideEffect)
        }
    }
}

extension StateMachine {
    /// Create a state machine using the declarative `@TransitionBuilder` DSL
    ///
    /// ```swift
    /// let machine = StateMachine<OrderState, OrderEvent>(initial: .pending) {
    ///     Transition(from: .pending,   on: .confirm, to: .confirmed)
    ///     Transition(from: .confirmed, on: .ship,    to: .shipped)
    /// }
    /// ```
    public init(
        initial: State,
        logger: StateLogger? = nil,
        historyDepth: Int? = nil,
        enableMetrics: Bool = false,
        @TransitionBuilder<State, Event> transitions: () -> [Transition<State, Event>]
    ) {
        self.init(
            initial: initial,
            transitions: transitions(),
            logger: logger,
            historyDepth: historyDepth,
            enableMetrics: enableMetrics
        )
    }
}

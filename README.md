# StateKit

[![Tests](https://github.com/philiprehberger/swift-state-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/swift-state-kit/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-state-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/philiprehberger/swift-state-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-state-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/philiprehberger/swift-state-kit)

![StateKit](https://raw.githubusercontent.com/philiprehberger/swift-state-kit/main/package-card.webp)

Type-safe async state machine with built-in logging and SwiftUI bindings

## Requirements

- Swift >= 6.0
- macOS 13+ / iOS 16+ / tvOS 16+ / watchOS 9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/philiprehberger/swift-state-kit.git", from: "0.21.0")
]
```

Then add `"StateKit"` to your target dependencies:

```swift
.target(name: "YourTarget", dependencies: [
    .product(name: "StateKit", package: "swift-state-kit")
])
```

## Usage

```swift
import StateKit

// Define states and events
enum OrderState: Hashable, Sendable {
    case pending, confirmed, shipped, delivered
}

enum OrderEvent: Hashable, Sendable {
    case confirm, ship, deliver
}

// Define transitions
let machine = StateMachine(
    initial: OrderState.pending,
    transitions: [
        Transition(from: .pending, on: .confirm, to: .confirmed),
        Transition(from: .confirmed, on: .ship, to: .shipped),
        Transition(from: .shipped, on: .deliver, to: .delivered)
    ]
)

let state = try await machine.send(.confirm)  // => .confirmed
```

### Builder DSL

```swift
import StateKit

let machine = StateMachine<OrderState, OrderEvent>(initial: .pending) {
    Transition(from: .pending,   on: .confirm, to: .confirmed)
    Transition(from: .confirmed, on: .ship,    to: .shipped)
    Transition(from: .shipped,   on: .deliver, to: .delivered)

    // Multi-source helper expands into one transition per source
    Transition.from([.pending, .confirmed, .shipped], on: .cancel, to: .cancelled)
}
```

The `@TransitionBuilder` result builder also supports `if`, `if let`, `if/else`, and `for` blocks inside the closure.

### Waiting for a State

```swift
import StateKit

// Suspend until the machine reaches .delivered (optionally with a timeout)
let final = try await machine.waitFor(.delivered, timeout: .seconds(60))
```

Returns immediately if the machine is already in the target state. Throws `StateMachineError.waitTimeout` if the optional duration elapses first.

### Previewing a Transition

```swift
import StateKit

// Resolve where an event *would* lead — honoring guards — without transitioning
if let next = await machine.peek(.confirm) {
    print("Confirm would move to \(next)")
}
```

`peek(_:)` runs the same matching and guard logic as `send(_:)` but never mutates state, runs side effects, or records history. Returns `nil` if no transition applies. Unlike `canSend(_:)`, it evaluates guard conditions and returns the destination state.

### Sending a Sequence of Events

```swift
import StateKit

// Apply several events in order, returning the final state
let final = try await machine.send([.confirm, .ship, .deliver])  // => .delivered
```

Events are applied one at a time. If an event is invalid in the state reached so far, `send(_:)` throws and the events applied before it remain committed.

### Sending Without Throwing

```swift
import StateKit

// Returns nil instead of throwing when the event does not apply in the current state
if let next = try await machine.sendIfPossible(.confirm) {
    print("Moved to \(next)")
}
```

`sendIfPossible(_:)` behaves exactly like `send(_:)` when a transition matches — side effects, middleware, entry/exit actions, and history all run. Only `StateMachineError.invalidTransition` is swallowed; side effect failures still throw.

### Async Side Effects

```swift
Transition(from: .pending, on: .confirm, to: .confirmed, sideEffect: {
    try await sendConfirmationEmail()
})
```

Label the closure `sideEffect:` — an unlabeled trailing closure binds to `guard:` instead.

### Logging

```swift
let machine = StateMachine(
    initial: OrderState.pending,
    transitions: transitions,
    logger: .console
)
// Logs: "[StateKit] pending --confirm--> confirmed"
```

### Timeout Transitions

```swift
import StateKit

// Auto-transition to error after 30 seconds in loading state
await machine.addTimeout(TimeoutTransition(
    from: .loading, after: .seconds(30), on: .timeout, to: .error
))
```

Timeouts auto-cancel if the state changes before the duration expires.

### Transition Metrics

```swift
import StateKit

let machine = StateMachine(initial: OrderState.pending, transitions: transitions, enableMetrics: true)
try await machine.send(.confirm)

let metrics = await machine.metrics
metrics?.totalTransitions                            // 1
metrics?.transitionCount(from: .pending, on: .confirm)  // 1
metrics?.eventCount(.confirm)                        // count across every source state
metrics?.allTransitionCounts                         // every transition, most frequent first
metrics?.mostFrequentTransition                      // the hottest transition, if any
metrics?.timeInState(.confirmed)                     // includes the visit in progress
```

### Diagram Export

```swift
import StateKit

print(await machine.exportMermaid())  // stateDiagram-v2, renders as-is in Markdown
print(await machine.exportDOT())      // Graphviz DOT
```

Both exports mark the initial state and highlight the current one. State descriptions containing spaces or punctuation are sanitized for Mermaid and escaped for DOT, and wildcard transitions leave an `anyState` pseudo-state rather than Mermaid's `[*]` start marker.

### State Persistence

```swift
import StateKit

// Save state
let snapshot = await machine.snapshot()
let data = try JSONEncoder().encode(snapshot)

// Restore state
let decoded = try JSONDecoder().decode(StateMachineSnapshot<OrderState>.self, from: data)
try await machine.restore(from: decoded)
```

### Middleware

```swift
import StateKit

struct AuthMiddleware: TransitionMiddleware {
    func intercept(
        from: OrderState, event: OrderEvent, to: OrderState,
        next: @Sendable () async throws -> Void
    ) async throws {
        guard await isAuthorized() else { throw AuthError.denied }
        try await next()
    }
}

await machine.addMiddleware(AuthMiddleware())
```

Middleware runs in order. Each must call `next()` to proceed or throw to reject.

### Entry and Exit Actions

```swift
import StateKit

let machine = StateMachine(initial: OrderState.pending, transitions: transitions)

await machine.onEnter(.shipped) {
    try await sendTrackingNotification()
}

await machine.onExit(.pending) {
    try await logOrderStart()
}
```

Exit actions run before the state changes, entry actions run after.

### Async State Streams

```swift
import StateKit

let machine = StateMachine(initial: OrderState.pending, transitions: transitions)

// Observe state changes reactively
Task {
    for await state in await machine.stateStream {
        print("State changed to: \(state)")
    }
}

// Or observe full transitions
Task {
    for await (from, event, to) in await machine.transitionStream {
        print("\(from) --\(event)--> \(to)")
    }
}
```

### Wildcard Transitions

```swift
import StateKit

// Matches from any state — useful for global events like reset
let transitions = [
    Transition(from: .idle, on: .start, to: .loading),
    Transition(from: .loading, on: .succeed, to: .loaded),
    Transition(fromAny: .reset, to: .idle)  // works from any state
]
```

Specific transitions are always checked before wildcards.

### Guard Conditions

```swift
import StateKit

let transitions = [
    Transition(from: .idle, on: .start, to: .loading, guard: { await isNetworkAvailable() }),
    Transition(from: .idle, on: .start, to: .error, guard: { true })  // fallback
]
```

When multiple transitions match the same state and event, guard conditions are evaluated in order. The first transition whose guard returns `true` is taken.

### State History and Undo

```swift
import StateKit

let machine = StateMachine(
    initial: OrderState.pending,
    transitions: transitions,
    historyDepth: 0  // 0 = unlimited, nil = disabled
)

try await machine.send(.confirm)
try await machine.send(.ship)

// Inspect history
let history = await machine.history  // [pending→confirmed, confirmed→shipped]

// Undo last transition
let restored = try await machine.undo()  // => .confirmed
```

### SwiftUI Integration

```swift
struct OrderView: View {
    @State private var machine: ObservableStateMachine<OrderState, OrderEvent>?

    var body: some View {
        if let machine {
            VStack {
                Text("Status: \(machine.state)")
                Button("Confirm") { Task { try await machine.send(.confirm) } }
            }
        }
    }
}
```

## API

### StateMachine

| Method | Description |
|--------|-------------|
| `init(initial:transitions:logger:historyDepth:enableMetrics:)` | Create a state machine with initial state and transitions |
| `send(_:)` | Send an event to trigger a transition |
| `send(_:)` (array) | Send a sequence of events in order, returning the final state |
| `sendIfPossible(_:)` | Send an event, returning `nil` instead of throwing when no transition applies |
| `peek(_:)` | Resolve the destination state for an event (honoring guards) without transitioning |
| `canSend(_:)` | Check if an event is valid in the current state |
| `waitFor(_:timeout:)` | Suspend until the machine reaches a target state, with optional timeout |
| `undo()` | Revert to the previous state (requires history) |
| `onTransition(_:)` | Register a callback for state changes |
| `onEnter(_:perform:)` | Register an action for when a state is entered |
| `onExit(_:perform:)` | Register an action for when a state is exited |
| `addMiddleware(_:)` | Add a middleware to the transition pipeline |
| `reset()` | Reset to initial state, clearing history |
| `validEvents` | Set of events valid in the current state |
| `validEvents(for:)` | Set of events valid for a given state |
| `validate()` | Check transition table for duplicates, terminal states, and unreachable states |
| `snapshot()` | Create a Codable snapshot of the current state |
| `restore(from:)` | Restore state from a snapshot |
| `addTimeout(_:)` | Register an automatic timeout transition |
| `metrics` | Transition metrics (if enabled) |
| `resetMetrics()` | Reset metrics counters |
| `exportDOT()` | Export transition graph as Graphviz DOT |
| `exportMermaid()` | Export transition graph as a Mermaid `stateDiagram-v2` |
| `attach(child:to:)` | Attach a child state machine to a parent state |
| `currentState` | The current state |
| `initialState` | The initial state the machine was created with |
| `history` | Array of past transitions |
| `canUndo` | Whether an undo operation is available |
| `stateStream` | `AsyncStream<State>` emitting new states after transitions |
| `transitionStream` | `AsyncStream` of `(from, event, to)` tuples |

### TransitionMetrics

| Property/Method | Description |
|-----------------|-------------|
| `totalTransitions` | Total number of transitions recorded |
| `transitionCount(from:on:)` | Count for one specific transition |
| `eventCount(_:)` | Count for an event across every source state |
| `allTransitionCounts` | Every recorded transition with its count, most frequent first |
| `mostFrequentTransition` | The most frequently taken transition, or `nil` |
| `timeInState(_:)` | Total time in a state, including the visit in progress |
| `reset()` | Clear all counters and timings |

### TransitionValidation

| Property | Description |
|----------|-------------|
| `duplicates` | Transitions sharing a `(from, event)` pair without guards |
| `terminalStates` | States reachable as a target with no outgoing transitions |
| `unreachableStates` | States in the table that cannot be reached from the initial state |
| `isValid` | Whether the table has no duplicates |

### Transition

| Property | Description |
|----------|-------------|
| `init(from:on:to:guard:sideEffect:)` | Create a transition from a specific state |
| `init(fromAny:to:guard:sideEffect:)` | Create a wildcard transition from any state |
| `from(_:on:to:guard:sideEffect:)` | Static helper expanding a list of source states into one transition each |
| `from` | Source state (`nil` for wildcard) |
| `event` | Triggering event |
| `to` | Destination state |
| `guardCondition` | Optional async predicate that must return `true` for the transition |
| `sideEffect` | Optional async closure executed during transition |

### StateMachine builder init

| Init | Description |
|------|-------------|
| `init(initial:logger:historyDepth:enableMetrics:_:)` | Convenience initializer accepting a `@TransitionBuilder` closure |

### ObservableStateMachine

| Property/Method | Description |
|-----------------|-------------|
| `init(machine:)` | Create wrapper, reading initial state from the machine |
| `init(machine:initialState:)` | Create wrapper with explicit initial state |
| `state` | Current state (observable) |
| `isTransitioning` | Whether a transition is in progress |
| `send(_:)` | Send an event |
| `canSend(_:)` | Check if an event is valid |
| `undo()` | Revert to the previous state |
| `canUndo` | Whether an undo operation is available |

## Development

```bash
swift build
swift test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/swift-state-kit)

🐛 [Report issues](https://github.com/philiprehberger/swift-state-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/swift-state-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)

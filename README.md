# StateKit

[![Tests](https://github.com/philiprehberger/swift-state-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/swift-state-kit/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-state-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/philiprehberger/swift-state-kit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fphiliprehberger%2Fswift-state-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/philiprehberger/swift-state-kit)

Type-safe async state machine with built-in logging and SwiftUI bindings

## Requirements

- Swift >= 6.0
- macOS 13+ / iOS 16+ / tvOS 16+ / watchOS 9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/philiprehberger/swift-state-kit.git", from: "0.1.0")
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

### Async Side Effects

```swift
Transition(from: .pending, on: .confirm, to: .confirmed) {
    try await sendConfirmationEmail()
}
```

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
| `init(initial:transitions:logger:historyDepth:)` | Create a state machine with initial state and transitions |
| `send(_:)` | Send an event to trigger a transition |
| `canSend(_:)` | Check if an event is valid in the current state |
| `undo()` | Revert to the previous state (requires history) |
| `onTransition(_:)` | Register a callback for state changes |
| `onEnter(_:perform:)` | Register an action for when a state is entered |
| `onExit(_:perform:)` | Register an action for when a state is exited |
| `addMiddleware(_:)` | Add a middleware to the transition pipeline |
| `reset()` | Reset to initial state, clearing history |
| `validEvents` | Set of events valid in the current state |
| `validEvents(for:)` | Set of events valid for a given state |
| `validate()` | Check transition table for duplicates and terminal states |
| `snapshot()` | Create a Codable snapshot of the current state |
| `restore(from:)` | Restore state from a snapshot |
| `addTimeout(_:)` | Register an automatic timeout transition |
| `currentState` | The current state |
| `initialState` | The initial state the machine was created with |
| `history` | Array of past transitions |
| `canUndo` | Whether an undo operation is available |
| `stateStream` | `AsyncStream<State>` emitting new states after transitions |
| `transitionStream` | `AsyncStream` of `(from, event, to)` tuples |

### Transition

| Property | Description |
|----------|-------------|
| `init(from:on:to:guard:sideEffect:)` | Create a transition from a specific state |
| `init(fromAny:to:guard:sideEffect:)` | Create a wildcard transition from any state |
| `from` | Source state (`nil` for wildcard) |
| `event` | Triggering event |
| `to` | Destination state |
| `guardCondition` | Optional async predicate that must return `true` for the transition |
| `sideEffect` | Optional async closure executed during transition |

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

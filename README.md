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

### SwiftUI Integration

```swift
struct OrderView: View {
    @State private var machine = ObservableStateMachine(machine: orderMachine)

    var body: some View {
        VStack {
            Text("Status: \(machine.state)")
            Button("Confirm") { Task { try await machine.send(.confirm) } }
                .disabled(!await machine.canSend(.confirm))
        }
    }
}
```

## API

### StateMachine

| Method | Description |
|--------|-------------|
| `init(initial:transitions:logger:)` | Create a state machine with initial state and transitions |
| `send(_:)` | Send an event to trigger a transition |
| `canSend(_:)` | Check if an event is valid in the current state |
| `onTransition(_:)` | Register a callback for state changes |
| `currentState` | The current state |

### Transition

| Property | Description |
|----------|-------------|
| `from` | Source state |
| `event` | Triggering event |
| `to` | Destination state |
| `sideEffect` | Optional async closure executed during transition |

### ObservableStateMachine

| Property/Method | Description |
|-----------------|-------------|
| `state` | Current state (observable) |
| `isTransitioning` | Whether a transition is in progress |
| `send(_:)` | Send an event |
| `canSend(_:)` | Check if an event is valid |

## Development

```bash
swift build
swift test
```

## Support

[💬 Bluesky](https://bsky.app/profile/philiprehberger.bsky.social) · [🐦 X](https://x.com/philiprehberger) · [💼 LinkedIn](https://linkedin.com/in/philiprehberger) · [🌐 Website](https://philiprehberger.com) · [📦 GitHub](https://github.com/philiprehberger) · [☕ Buy Me a Coffee](https://buymeacoffee.com/philiprehberger) · [❤️ GitHub Sponsors](https://github.com/sponsors/philiprehberger)

## License

[MIT](LICENSE)

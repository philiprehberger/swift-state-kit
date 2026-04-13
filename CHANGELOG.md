# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.18.0] - 2026-04-13

### Added
- Hierarchical state machines via `attach(child:to:)`
- Child machines auto-reset on parent state entry and exit

## [0.17.0] - 2026-04-13

### Added
- `exportDOT()` for Graphviz DOT graph export
- `exportMermaid()` for Mermaid stateDiagram-v2 export
- Current state highlighting in exports

## [0.16.0] - 2026-04-13

### Added
- `TransitionMetrics` for tracking transition counts and state durations
- `enableMetrics` parameter on `StateMachine.init`
- `metrics` property and `resetMetrics()` method

## [0.15.0] - 2026-04-13

### Fixed
- Added async convenience `init(machine:)` on `ObservableStateMachine` (already shipped in v0.2.0, version reserved for alignment)

## [0.14.0] - 2026-04-13

### Added
- `Equatable` conformance for `StateMachineError`
- `isInvalidTransition` and `isSideEffectFailed` convenience properties

## [0.13.0] - 2026-04-13

### Added
- `StateLogger.osLog(subsystem:category:)` using Apple's os.Logger
- `StateLogger.osLog` convenience static property

## [0.12.0] - 2026-04-13

### Added
- `TimeoutTransition` type for automatic state transitions after a duration
- `addTimeout(_:)` method on `StateMachine`
- Timeouts auto-cancel when state changes before firing

## [0.11.0] - 2026-04-13

### Added
- `StateMachineSnapshot` Codable type for state persistence
- `snapshot()` method for capturing current state
- `restore(from:)` method for restoring state from a snapshot
- `invalidState` error case on `StateMachineError`

## [0.10.0] - 2026-04-13

### Added
- `TransitionValidation` type for checking transition tables
- `validate()` method detecting duplicate transitions and terminal states

## [0.9.0] - 2026-04-13

### Added
- `validEvents` computed property returning valid events for the current state
- `validEvents(for:)` method for querying events valid in any state

## [0.8.0] - 2026-04-13

### Added
- `reset()` method to return state machine to initial state
- Reset clears history and fires exit/entry actions

## [0.7.0] - 2026-04-13

### Added
- `TransitionMiddleware` protocol for pluggable transition interceptors
- `addMiddleware(_:)` method on `StateMachine`
- Middleware chain with nested `next()` execution pattern

## [0.6.0] - 2026-04-13

### Added
- `onEnter(_:perform:)` to register actions when entering a state
- `onExit(_:perform:)` to register actions when exiting a state
- Exit actions execute before state change, entry actions after

## [0.5.0] - 2026-04-13

### Added
- `stateStream` property returning `AsyncStream<State>` for reactive state observation
- `transitionStream` property returning `AsyncStream` of `(from, event, to)` tuples
- Multiple concurrent subscribers supported

## [0.4.0] - 2026-04-13

### Added
- Wildcard transitions via `Transition(fromAny:to:)` that match from any state
- Specific transitions take priority over wildcards
- `matches(state:event:)` internal helper on `Transition`

## [0.3.0] - 2026-04-13

### Added
- Guard conditions on transitions via `guard:` parameter
- Guard evaluation with fallthrough to next matching transition

## [0.2.0] - 2026-04-13

### Added
- State history tracking with configurable `historyDepth` parameter
- `undo()` method to revert to the previous state
- `history` property for inspecting past transitions
- `canUndo` property to check if undo is available
- `initialState` read-only property on `StateMachine`
- `StateHistoryEntry` type with `from`, `event`, `to`, and `timestamp`
- `noHistoryToUndo` error case on `StateMachineError`
- `CustomDebugStringConvertible` conformance for `Transition`
- Async convenience `init(machine:)` on `ObservableStateMachine`
- `undo()` and `canUndo` on `ObservableStateMachine`

## [0.1.0] - 2026-04-02

### Added
- `StateMachine` actor with generic `State` and `Event` types
- Type-safe transition definitions with `Transition` struct
- Async side effects on transitions
- `canSend(_:)` for checking valid transitions
- `onTransition` callback for observing state changes
- `StateLogger` for built-in transition logging
- `ObservableStateMachine` for SwiftUI integration with `@Observable`
- `StateMachineError` for invalid transitions and side-effect failures
- Zero external dependencies

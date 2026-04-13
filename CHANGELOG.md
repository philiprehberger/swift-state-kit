# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

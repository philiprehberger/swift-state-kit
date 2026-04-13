import Testing
import Foundation
@testable import StateKit

enum CodableState: String, Hashable, Sendable, Codable {
    case idle, loading, loaded
}

enum CodableEvent: String, Hashable, Sendable, Codable {
    case start, succeed, reset
}

@Suite("Snapshot Persistence Tests")
struct SnapshotTests {
    private func makeTransitions() -> [Transition<CodableState, CodableEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loaded, on: .reset, to: .idle)
        ]
    }

    @Test("Snapshot captures current state")
    func snapshotCaptures() async throws {
        let machine = StateMachine(initial: CodableState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let snap = await machine.snapshot()
        #expect(snap.currentState == .loading)
    }

    @Test("Snapshot round-trips through JSON")
    func snapshotRoundTrip() async throws {
        let machine = StateMachine(initial: CodableState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let snap = await machine.snapshot()
        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(StateMachineSnapshot<CodableState>.self, from: data)
        #expect(decoded.currentState == .loading)
    }

    @Test("Restore sets state from snapshot")
    func restoreFromSnapshot() async throws {
        let machine = StateMachine(initial: CodableState.idle, transitions: makeTransitions())
        let snap = StateMachineSnapshot(currentState: CodableState.loaded)
        try await machine.restore(from: snap)
        let state = await machine.currentState
        #expect(state == .loaded)
    }

    @Test("Restore with invalid state throws")
    func restoreInvalidState() async {
        let transitions: [Transition<CodableState, CodableEvent>] = [
            Transition(from: .idle, on: .start, to: .loading)
        ]
        let machine = StateMachine(initial: CodableState.idle, transitions: transitions)
        let snap = StateMachineSnapshot(currentState: CodableState.loaded)
        do {
            try await machine.restore(from: snap)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
        }
    }
}

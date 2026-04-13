#if canImport(Observation)
import Testing
@testable import StateKit

@Suite("ObservableStateMachine Tests")
struct ObservableStateMachineTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded),
            Transition(from: .loading, on: .fail, to: .error),
            Transition(from: .error, on: .reset, to: .idle)
        ]
    }

    @Test("send updates state property")
    func sendUpdatesState() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let observable = ObservableStateMachine(machine: machine, initialState: .idle)
        let newState = try await observable.send(.start)
        #expect(newState == .loading)
        #expect(observable.state == .loading)
    }

    @Test("canSend returns correct values")
    func canSendCheck() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let observable = ObservableStateMachine(machine: machine, initialState: .idle)
        let canStart = await observable.canSend(.start)
        #expect(canStart == true)
        let canSucceed = await observable.canSend(.succeed)
        #expect(canSucceed == false)
    }

    @Test("Invalid event throws and state unchanged")
    func invalidEventThrows() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let observable = ObservableStateMachine(machine: machine, initialState: .idle)
        do {
            _ = try await observable.send(.succeed)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StateMachineError)
            #expect(observable.state == .idle)
        }
    }

    @Test("Async convenience init reads state from machine")
    func asyncInit() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let observable = await ObservableStateMachine(machine: machine)
        #expect(observable.state == .idle)
    }

    @Test("Undo restores observable state")
    func undoRestores() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions(), historyDepth: 0)
        let observable = ObservableStateMachine(machine: machine, initialState: .idle)
        try await observable.send(.start)
        let restored = try await observable.undo()
        #expect(restored == .idle)
        #expect(observable.state == .idle)
    }
}
#endif

import Testing
@testable import StateKit

@Suite("StateMachineError Tests")
struct ErrorTests {
    @Test("invalidTransition equality")
    func invalidTransitionEquality() {
        let a = StateMachineError.invalidTransition(from: "idle", event: "start")
        let b = StateMachineError.invalidTransition(from: "idle", event: "start")
        let c = StateMachineError.invalidTransition(from: "idle", event: "stop")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("noHistoryToUndo equality")
    func noHistoryEquality() {
        #expect(StateMachineError.noHistoryToUndo == StateMachineError.noHistoryToUndo)
    }

    @Test("invalidState equality")
    func invalidStateEquality() {
        let a = StateMachineError.invalidState("foo")
        let b = StateMachineError.invalidState("foo")
        let c = StateMachineError.invalidState("bar")
        #expect(a == b)
        #expect(a != c)
    }

    @Test("Different cases are not equal")
    func differentCases() {
        let a = StateMachineError.invalidTransition(from: "idle", event: "start")
        let b = StateMachineError.noHistoryToUndo
        #expect(a != b)
    }

    @Test("isInvalidTransition helper")
    func isInvalidTransition() {
        let e = StateMachineError.invalidTransition(from: "x", event: "y")
        #expect(e.isInvalidTransition)
        #expect(!e.isSideEffectFailed)
    }

    @Test("isSideEffectFailed helper")
    func isSideEffectFailed() {
        struct TestError: Error {}
        let e = StateMachineError.sideEffectFailed(TestError())
        #expect(e.isSideEffectFailed)
        #expect(!e.isInvalidTransition)
    }
}

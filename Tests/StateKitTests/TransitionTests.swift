import Testing
@testable import StateKit

@Suite("Transition Tests")
struct TransitionTests {
    @Test("debugDescription format")
    func debugDescription() {
        let transition = Transition<TestState, TestEvent>(from: .idle, on: .start, to: .loading)
        #expect(transition.debugDescription == "Transition(idle --start--> loading)")
    }
}

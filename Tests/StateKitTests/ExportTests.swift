import Testing
@testable import StateKit

@Suite("Export Tests")
struct ExportTests {
    private func makeTransitions() -> [Transition<TestState, TestEvent>] {
        [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(from: .loading, on: .succeed, to: .loaded)
        ]
    }

    @Test("DOT export contains all states and transitions")
    func dotExport() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let dot = await machine.exportDOT()
        #expect(dot.contains("digraph StateMachine"))
        #expect(dot.contains("\"idle\" -> \"loading\""))
        #expect(dot.contains("\"loading\" -> \"loaded\""))
        #expect(dot.contains("[label=\"start\"]"))
    }

    @Test("Mermaid export contains transitions")
    func mermaidExport() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let mermaid = await machine.exportMermaid()
        #expect(mermaid.contains("stateDiagram-v2"))
        #expect(mermaid.contains("idle --> loading : start"))
        #expect(mermaid.contains("loading --> loaded : succeed"))
    }

    @Test("DOT export highlights current state")
    func dotHighlightsCurrent() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let dot = await machine.exportDOT()
        #expect(dot.contains("\"loading\" [style=bold, color=blue]"))
    }
}

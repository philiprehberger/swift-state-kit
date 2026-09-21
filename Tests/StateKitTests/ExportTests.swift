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

    @Test("DOT export marks the initial state with a start node")
    func dotMarksInitialState() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let dot = await machine.exportDOT()
        #expect(dot.contains("__start [shape=point];"))
        #expect(dot.contains("__start -> \"idle\";"))
    }

    @Test("DOT export escapes quotes in descriptions")
    func dotEscapesQuotes() async {
        let transitions = [Transition(from: QuotedState.plain, on: TestEvent.start, to: .quoted)]
        let machine = StateMachine(initial: QuotedState.plain, transitions: transitions)
        let dot = await machine.exportDOT()
        // The raw description contains a double quote; it must be backslash-escaped in DOT
        #expect(dot.contains("\\\""))
        #expect(!dot.contains("\"needs \"escaping\"\""))
    }

    @Test("Mermaid export declares states and the initial transition")
    func mermaidDeclaresStates() async {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        let mermaid = await machine.exportMermaid()
        #expect(mermaid.contains("state \"idle\" as idle"))
        #expect(mermaid.contains("state \"loading\" as loading"))
        #expect(mermaid.contains("[*] --> idle"))
    }

    @Test("Mermaid export notes the current state with valid syntax")
    func mermaidNotesCurrentState() async throws {
        let machine = StateMachine(initial: TestState.idle, transitions: makeTransitions())
        try await machine.send(.start)
        let mermaid = await machine.exportMermaid()
        #expect(mermaid.contains("note right of loading : current state"))
        // The old composite-state block was not valid stateDiagram-v2
        #expect(!mermaid.contains("note: current state"))
    }

    @Test("Mermaid export routes wildcards through a pseudo-state, not the start marker")
    func mermaidWildcardPseudoState() async {
        let transitions: [Transition<TestState, TestEvent>] = [
            Transition(from: .idle, on: .start, to: .loading),
            Transition(fromAny: .reset, to: .idle)
        ]
        let machine = StateMachine(initial: TestState.idle, transitions: transitions)
        let mermaid = await machine.exportMermaid()
        #expect(mermaid.contains("state \"any state\" as anyState"))
        #expect(mermaid.contains("anyState --> idle : reset"))
        // [*] appears exactly once — as the entry into the initial state
        #expect(mermaid.components(separatedBy: "[*]").count - 1 == 1)
    }

    @Test("Mermaid export sanitizes descriptions that are not identifiers")
    func mermaidSanitizesIdentifiers() async {
        let transitions = [Transition(from: SpacedState.needsWork, on: TestEvent.start, to: .done)]
        let machine = StateMachine(initial: SpacedState.needsWork, transitions: transitions)
        let mermaid = await machine.exportMermaid()
        #expect(mermaid.contains("state \"needs work\" as needs_work"))
        #expect(mermaid.contains("needs_work --> done : start"))
    }
}

enum QuotedState: Hashable, Sendable, CustomStringConvertible {
    case plain, quoted

    var description: String {
        switch self {
        case .plain: return "plain"
        case .quoted: return "needs \"escaping\""
        }
    }
}

enum SpacedState: Hashable, Sendable, CustomStringConvertible {
    case needsWork, done

    var description: String {
        switch self {
        case .needsWork: return "needs work"
        case .done: return "done"
        }
    }
}

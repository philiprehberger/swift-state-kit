import Foundation

extension StateMachine {
    /// Export the state machine as a Graphviz DOT graph
    ///
    /// The initial state is marked with a point-shaped start node, the current state is
    /// highlighted, and wildcard sources are drawn from a `*` node. Quotes and backslashes in
    /// state and event descriptions are escaped so the output stays parseable.
    public func exportDOT() -> String {
        var lines: [String] = ["digraph StateMachine {"]
        lines.append("    rankdir=LR;")
        lines.append("    node [shape=circle];")
        lines.append("    __start [shape=point];")
        lines.append("    __start -> \"\(Self.dotEscaped(initialState))\";")
        lines.append("    \"\(Self.dotEscaped(currentState))\" [style=bold, color=blue];")

        for t in transitions {
            let from = t.from.map { Self.dotEscaped($0) } ?? "*"
            let to = Self.dotEscaped(t.to)
            let label = Self.dotEscaped(t.event)
            lines.append("    \"\(from)\" -> \"\(to)\" [label=\"\(label)\"];")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    /// Export the state machine as a Mermaid `stateDiagram-v2`
    ///
    /// Every state is declared with a sanitized identifier and its real description as the
    /// label, so states whose descriptions contain spaces or punctuation still render. The
    /// initial state is reached from `[*]`, wildcard transitions leave a dedicated `anyState`
    /// pseudo-state, and the current state is annotated with a note.
    public func exportMermaid() -> String {
        var registry = MermaidIdentifiers()

        // Declare the initial state first so the diagram reads top-down from the entry point
        let initialID = registry.identifier(for: initialState)

        var transitionLines: [String] = []
        for t in transitions {
            let fromID = t.from.map { registry.identifier(for: $0) } ?? registry.wildcardIdentifier()
            let toID = registry.identifier(for: t.to)
            transitionLines.append("    \(fromID) --> \(toID) : \(MermaidIdentifiers.label(for: t.event))")
        }

        let currentID = registry.identifier(for: currentState)

        var lines: [String] = ["stateDiagram-v2"]
        lines.append(contentsOf: registry.declarations)
        lines.append("    [*] --> \(initialID)")
        lines.append(contentsOf: transitionLines)
        lines.append("    note right of \(currentID) : current state")
        return lines.joined(separator: "\n")
    }

    /// Escape a value for use inside a DOT quoted string
    private static func dotEscaped(_ value: Any) -> String {
        String(describing: value)
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

/// Assigns stable, identifier-safe Mermaid ids to state descriptions
private struct MermaidIdentifiers {
    /// The pseudo-state wildcard transitions leave from
    static let wildcardID = "anyState"

    private(set) var declarations: [String] = []
    private var ids: [String: String] = [:]
    private var used: Set<String> = [wildcardID]

    /// A Mermaid-safe rendering of a value's description, for use as a label
    static func label(for value: Any) -> String {
        String(describing: value)
            .replacingOccurrences(of: "\"", with: "'")
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// The identifier for a state, declaring it on first use
    mutating func identifier(for value: Any) -> String {
        let label = Self.label(for: value)
        if let existing = ids[label] { return existing }

        var base = String(label.map { ($0.isLetter || $0.isNumber) ? $0 : "_" })
        if base.first?.isLetter != true { base = "s\(base)" }

        var candidate = base
        var suffix = 2
        while used.contains(candidate) {
            candidate = "\(base)\(suffix)"
            suffix += 1
        }

        used.insert(candidate)
        ids[label] = candidate
        declarations.append("    state \"\(label)\" as \(candidate)")
        return candidate
    }

    /// The wildcard pseudo-state, declaring it on first use
    mutating func wildcardIdentifier() -> String {
        if !declarations.contains(where: { $0.hasSuffix("as \(Self.wildcardID)") }) {
            declarations.append("    state \"any state\" as \(Self.wildcardID)")
        }
        return Self.wildcardID
    }
}

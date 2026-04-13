import Foundation

extension StateMachine {
    /// Export the state machine as a DOT graph
    public func exportDOT() -> String {
        var lines: [String] = ["digraph StateMachine {"]
        lines.append("    rankdir=LR;")
        lines.append("    node [shape=circle];")
        lines.append("    \"\(currentState)\" [style=bold, color=blue];")

        for t in transitions {
            let from = t.from.map { "\($0)" } ?? "*"
            lines.append("    \"\(from)\" -> \"\(t.to)\" [label=\"\(t.event)\"];")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    /// Export the state machine as a Mermaid stateDiagram-v2
    public func exportMermaid() -> String {
        var lines: [String] = ["stateDiagram-v2"]

        for t in transitions {
            let from = t.from.map { "\($0)" } ?? "[*]"
            lines.append("    \(from) --> \(t.to) : \(t.event)")
        }

        lines.append("    state \"\(currentState)\" as \(currentState) {")
        lines.append("        note: current state")
        lines.append("    }")

        return lines.joined(separator: "\n")
    }
}

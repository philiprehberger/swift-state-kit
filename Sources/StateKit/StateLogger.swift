import Foundation

/// A logger for state machine transitions
public struct StateLogger: Sendable {
    /// The logging function
    public let log: @Sendable (String) -> Void

    /// A console logger that prints to stdout
    public static let console = StateLogger { print($0) }

    /// Create a custom logger
    public init(log: @escaping @Sendable (String) -> Void) {
        self.log = log
    }
}

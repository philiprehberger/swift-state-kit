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

#if canImport(OSLog)
import OSLog

extension StateLogger {
    /// A logger using Apple's os.Logger with a custom subsystem and category
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public static func osLog(subsystem: String = "com.philiprehberger.StateKit", category: String = "transitions") -> StateLogger {
        let logger = os.Logger(subsystem: subsystem, category: category)
        return StateLogger { logger.info("\($0)") }
    }

    /// A logger using Apple's os.Logger with default subsystem
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public static let osLog = StateLogger.osLog()
}
#endif

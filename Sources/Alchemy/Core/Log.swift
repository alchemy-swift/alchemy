import Logging

/// Convenience struct for logging logs of various levels to a default `Logger`.
/// By default, this logger has label `alchemy_default_logger`.
///
/// ```
/// Log.debug("Hello, world!")
/// ```
///
/// You can set a custom default logger like so:
/// ```
/// // In Application.setup...
/// Log.logger = Logger(label: "my_default_logger")
/// ```
///
///
public struct Log {
    /// The default logger to which all logs will be logged. It has label
    /// `alchemy_default_logger`.
    public static var logger = Logger(label: "alchemy_default_logger")
    
    /// Log a message with the `Logger.Level.trace` log level.
    public static func trace(_ message: String) {
        Log.logger.trace(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.trace` log level.
    public static func debug(_ message: String) {
        Log.logger.debug(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.info` log level.
    public static func info(_ message: String) {
        Log.logger.info(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.notice` log level.
    public static func notice(_ message: String) {
        Log.logger.notice(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.warning` log level.
    public static func warning(_ message: String) {
        Log.logger.warning(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.error` log level.
    public static func error(_ message: String) {
        Log.logger.error(.init(stringLiteral: message))
    }
    
    /// Log a message with the `Logger.Level.critical` log level.
    public static func critical(_ message: String) {
        Log.logger.critical(.init(stringLiteral: message))
    }
}

import Logging

public struct Log {
    /// TODO: easy emission of logs of various levels to other places. i.e. critical to slack, all to datadog,
    /// etc.
    /// Also support for metadata?
    /// Also filenames, line numbers, timestamps, etc
    
    private static let logger = Logger(label: "inc.alchemy.your_app")
    
    // An optional prefix for all logs. (will remove later, useful for debugging for now)
    public static var prefix: String? = "[ Alchemy ] "
    
    public static func trace(_ message: String) {
        Log.logger.trace(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func debug(_ message: String) {
        Log.logger.debug(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func info(_ message: String) {
        Log.logger.info(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func notice(_ message: String) {
        Log.logger.notice(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func warning(_ message: String) {
        Log.logger.warning(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func error(_ message: String) {
        Log.logger.error(.init(stringLiteral: (prefix ?? "") + message))
    }
    
    public static func critical(_ message: String) {
        Log.logger.critical(.init(stringLiteral: (prefix ?? "") + message))
    }
}

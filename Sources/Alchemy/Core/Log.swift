import Logging

public struct Log {
    /// TODO: easy emission of logs of various levels to other places. i.e. critical to slack, all to datadog,
    /// etc.
    /// Also support for metadata?
    /// Also filenames, line numbers, timestamps, etc
    
    private static let logger = Logger(label: "inc.alchemy.your_app")
    
    public static func trace(_ message: String) {
        Log.logger.trace(.init(stringLiteral: message))
    }
    
    public static func debug(_ message: String) {
        Log.logger.debug(.init(stringLiteral: message))
    }
    
    public static func info(_ message: String) {
        Log.logger.info(.init(stringLiteral: message))
    }
    
    public static func notice(_ message: String) {
        Log.logger.notice(.init(stringLiteral: message))
    }
    
    public static func warning(_ message: String) {
        Log.logger.warning(.init(stringLiteral: message))
    }
    
    public static func error(_ message: String) {
        Log.logger.error(.init(stringLiteral: message))
    }
    
    public static func critical(_ message: String) {
        Log.logger.critical(.init(stringLiteral: message))
    }
}

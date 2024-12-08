import Foundation

/// Convenience struct for logging logs of various levels to a default
/// `Logger`. By default, this logger has label `Alchemy`.
///
/// ```swift
/// Log.debug("Hello, world!")
/// ```
///
/// You can set a custom default logger like so:
/// ```swift
/// // In Application.boot...
/// Log.logger = Logger(label: "my_default_logger")
/// ```
extension Logger {

    // MARK: Conveniences

    /// Log a message with the `Logger.Level.trace` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func trace(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        trace(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.debug` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func debug(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        debug(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.info` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func info(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        info(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.notice` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func notice(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        notice(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.warning` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func warning(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        warning(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.error` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func error(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        error(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Log a message with the `Logger.Level.critical` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public func critical(_ message: String, metadata: Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        critical(Message(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }

    /// Returns a copy of this logger with the given level.
    public func withLevel(_ level: Logger.Level) -> Logger {
        var logger = self
        logger.logLevel = level
        return logger
    }

    // MARK: Comments

    /// Logs a "comment". Internal function intended for useful context during
    /// local dev only.
    func comment(_ message: String) {
        if !Container.isTest && Container.isDebug {
            if Container.isXcode {
                Log.info("\(message)")
            } else {
                print("  \(message)")
            }
        }
    }

    func dots(left: String, right: String) -> String {
        let padding = Container.isXcode ? 0 : 4
        return String(repeating: ".", count: Terminal.columns - left.count - right.count - 2 - padding)
    }

    public static let `default`: Logger = {
        let isTests = Container.isTest
        let defaultLevel: Logger.Level = Container.isTest ? .error : .info
        let level = Environment.logLevel ?? defaultLevel
        if Container.isXcode {
            return .xcode.withLevel(defaultLevel)
        } else {
            return .debug.withLevel(defaultLevel)
        }
    }()
}

extension Environment {
    fileprivate static var logLevel: Logger.Level? {
        if let value = CommandLine.value(for: "--log") ?? CommandLine.value(for: "-l"), let level = Logger.Level(rawValue: value) {
            return level
        } else if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"], let level = Logger.Level(rawValue: value) {
            return level
        } else {
            return nil
        }
    }
}

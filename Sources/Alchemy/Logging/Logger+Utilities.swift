import Logging

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

/*
 
 Conveniences around...

 1. Destination.
 2. Multiple destinations (MultiplexLogHandler).
 3. Built in destinations.
 4. Output Format.
 5. Using combos of the above depending on the environment.
 6. Sensible Defaults - prod = syslog? dev = local?
 7. Filtering (level, metadata?)
 8. Metadata
 9. Source & Service?

 */

extension Logger: Service {
    public struct Identifier: ServiceIdentifier {
        private let hashable: AnyHashable
        public init(hashable: AnyHashable) { self.hashable = hashable }
    }

    public static let alchemyDefault: Logger = {
        if Env.isProd {
            return .stdout
        } else if Env.isTest {
            return .null
        } else if Env.isXcode {
            return .xcode
        } else {
            return .debug
        }
    }()

    public func withLevel(_ level: Logger.Level) -> Logger {
        var logger = self
        logger.logLevel = level
        return logger
    }

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

    // MARK: Comments

    /// Logs a "comment". Internal function intended for useful context during
    /// local dev only.
    func comment(_ message: String) {
        if !Env.isTest && !Env.isProd {
            let padding = Env.isXcode ? "" : "  "
            print("\(padding)\(message)")
        }
    }

    func dots(left: String, right: String) -> String {
        let padding = Env.isXcode ? 0 : 4
        return String(repeating: ".", count: Terminal.columns - left.count - right.count - 2 - padding)
    }
}

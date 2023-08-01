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

struct Terminal {
    static var columns: Int = {
        let string = try! safeShell("tput cols").trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(string) ?? 80
    }()

    @discardableResult // Add to suppress warnings when you don't want/need a result
    private static func safeShell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash") //<--updated
        task.standardInput = nil

        try task.run() //<--updated

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}

public struct Log {
    /// The logger to which all logs will be logged. By default it's a
    /// logger with label `Alchemy`.
    public static var logger = Logger(label: "Alchemy", factory: { AlchemyLogger(label: $0) })
    private static var columns: Int?

    public static func comment(_ message: String) {
        print(message)
    }

    /// Log a message with the `Logger.Level.trace` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func trace(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.trace(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.debug` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func debug(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.debug(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.info` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func info(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.info(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.notice` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func notice(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.notice(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.warning` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func warning(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.warning(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.error` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func error(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.error(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
    
    /// Log a message with the `Logger.Level.critical` log level.
    ///
    /// - Parameters:
    ///   - message: the message to log.
    ///   - metadata: any metadata (a typealias of
    ///     `[String: Logger.MetadataType]`) to log.
    public static func critical(_ message: String, metadata: Logger.Metadata? = nil, file: String = #fileID, function: String = #function, line: UInt = #line) {
        Log.logger.critical(.init(stringLiteral: message), metadata: metadata, file: file, function: function, line: line)
    }
}

fileprivate struct AlchemyLogger: LogHandler {
    public var logLevel: Logger.Level = .info
    public var metadataProvider: Logger.MetadataProvider?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    private let label: String
    private var prettyMetadata: String?

    init(label: String, metadataProvider: Logger.MetadataProvider? = LoggingSystem.metadataProvider) {
        // Clear out the console on boot.
        print("")
        self.label = label
        self.metadataProvider = metadataProvider
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata explicitMetadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let effectiveMetadata = AlchemyLogger.prepareMetadata(base: self.metadata, provider: self.metadataProvider, explicit: explicitMetadata)

        let prettyMetadata: String?
        if let effectiveMetadata = effectiveMetadata {
            prettyMetadata = self.prettify(effectiveMetadata)
        } else {
            prettyMetadata = self.prettyMetadata
        }

        var _level = " \(level) ".uppercased()
        switch level {
        case .trace:
            _level = _level.black.onWhite
        case .debug:
            _level = _level.black.onCyan
        case .info:
            _level = _level.black.onBlue
        case .notice:
            _level = _level.black.onGreen
        case .warning:
            _level = _level.black.onYellow
        case .error:
            _level = _level.black.onLightRed
        case .critical:
            _level = _level.lightRed.onBlack
        }

        let showSource = Environment.SHOW_SOURCE == true
        let source = showSource ? " [\(source)]" : ""
        print("  \(_level) \(source)\(message)\(prettyMetadata.map { " \($0)" } ?? "") \n")
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    internal static func prepareMetadata(base: Logger.Metadata, provider: Logger.MetadataProvider?, explicit: Logger.Metadata?) -> Logger.Metadata? {
        var metadata = base

        let provided = provider?.get() ?? [:]

        guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
            // all per-log-statement values are empty
            return nil
        }

        if !provided.isEmpty {
            metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
        }

        if let explicit = explicit, !explicit.isEmpty {
            metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
        }

        return metadata
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        if metadata.isEmpty {
            return nil
        } else {
            return metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }.joined(separator: " ")
        }
    }
}

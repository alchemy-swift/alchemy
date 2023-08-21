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

    /// Logs a "comment". Internal function intended for useful context during
    /// local dev only.
    func comment(_ message: String) {
        if !Env.isTest && !Env.isProd {
            print(message)
        }
    }

    func dots(left: String, right: String) -> String {
        String(repeating: ".", count: Terminal.columns - left.count - right.count - 2)
    }

    func with(handler: LogHandler) {
        
    }

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

    public static let alchemyDefault = Logging.Logger(label: "Alchemy", factory: { AlchemyLogger(label: $0) })
}

fileprivate struct AlchemyLogger: LogHandler {
    typealias Level = Logger.Level
    typealias Message = Logger.Message
    typealias Metadata = Logger.Metadata
    typealias MetadataProvider = Logger.MetadataProvider

    public var logLevel: Logger.Level = .info
    public var metadataProvider: MetadataProvider?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    private let label: String
    private var prettyMetadata: String?

    init(label: String, metadataProvider: MetadataProvider? = LoggingSystem.metadataProvider) {
        // Clear out the console on boot.
        print("")
        self.label = label
        self.metadataProvider = metadataProvider
    }

    public func log(level: Level,
                    message: Message,
                    metadata explicitMetadata: Metadata?,
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

    internal static func prepareMetadata(base: Metadata, provider: MetadataProvider?, explicit: Metadata?) -> Metadata? {
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

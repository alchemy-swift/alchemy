extension Logger {
    public static let alchemyDefault = Logging.Logger(label: "Alchemy", factory: { DebugLogger(label: $0) })
}

private struct DebugLogger: LogHandler {
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

    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let effectiveMetadata = DebugLogger.prepareMetadata(base: self.metadata, provider: self.metadataProvider, explicit: metadata)

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

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    static func prepareMetadata(base: Logger.Metadata, provider: Logger.MetadataProvider?, explicit: Logger.Metadata?) -> Logger.Metadata? {
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

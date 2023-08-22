import Logging

extension Logger {
    public init(loggers: [Logger]) {
        self.init(label: "Alchemy") { _ in
            CompoundLogHandler(loggers)
        }
    }
}

public struct CompoundLogHandler: LogHandler {
    private var loggers: [Logger]
    private var effectiveLogLevel: Logger.Level

    public init(_ loggers: [Logger]) {
        self.loggers = loggers
        self.effectiveLogLevel = loggers.map { $0.logLevel }.min() ?? .trace
    }

    public var logLevel: Logger.Level {
        get { effectiveLogLevel }
        set {
            mutatingForEachHandler { $0.logLevel = newValue }
            effectiveLogLevel = newValue
        }
    }

    public var metadata: Logger.Metadata {
        get { [:] }
        set { }
    }

    public func log(level: Logger.Level,
                    message: Logger.Message,
                    metadata: Logger.Metadata?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        for logger in loggers where logger.logLevel <= level {
            logger.log(level: level, message, metadata: metadata, source: source, file: file, function: function, line: line)
        }
    }

    public subscript(metadataKey metadataKey: Logger.Metadata.Key) -> Logger.Metadata.Value? {
        get {
            for logger in loggers {
                if let value = logger[metadataKey: metadataKey] {
                    return value
                }
            }
            return nil
        }
        set {
            mutatingForEachHandler { $0[metadataKey: metadataKey] = newValue }
        }
    }

    private mutating func mutatingForEachHandler(_ mutator: (inout Logger) -> Void) {
        for index in loggers.indices {
            mutator(&loggers[index])
        }
    }
}

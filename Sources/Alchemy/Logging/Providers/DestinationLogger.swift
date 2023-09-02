public protocol LogDestination {
    func log(payload: LogPayload)
}

public struct LogPayload {
    public let label: String
    public let level: Logger.Level
    public let message: Logger.Message
    public let metadata: Logger.Metadata?
    public let source: String
    public let file: String
    public let function: String
    public let line: UInt
}

extension Logger {
    public init(label: String = "Alchemy", level: Logger.Level = .info, destination: LogDestination) {
        self.init(label: label, factory: { DestinationLogHandler(label: $0, metadata: [:], logLevel: level, destination: destination) })
    }
}

private struct DestinationLogHandler: LogHandler {
    let label: String
    var metadataProvider: Logger.MetadataProvider?
    var metadata: Logger.Metadata
    var logLevel: Logger.Level
    let destination: LogDestination

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let _metadata = self.metadata + metadataProvider?.get() + metadata
        let payload = LogPayload(label: label, level: level, message: message, metadata: _metadata, source: source, file: file, function: function, line: line)
        destination.log(payload: payload)
    }
}

extension Logger.Metadata? {
    static func + (lhs: Logger.Metadata?, rhs: Logger.Metadata?) -> Logger.Metadata? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs + rhs
    }
}

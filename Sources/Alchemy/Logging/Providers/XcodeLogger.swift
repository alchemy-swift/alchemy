import Logging
import OSLog

extension Logging.Logger {
    static var xcode: Logging.Logger {
        Logger(label: "Alchemy", destination: XcodeLogger())
    }
}

struct XcodeLogger: LogDestination {
    private let logger = Logger()

    func log(payload: LogPayload) {
        let metadataString = prettify(payload.metadata ?? [:]).map { " [\($0)]" } ?? ""
        let message = "\(payload.message)\(metadataString) "
        let logger = Logger(subsystem: payload.source, category: "Default")
        switch payload.level {
        case .trace:
            logger.trace("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .critical:
            logger.critical("\(message, privacy: .public)")
        }
    }

    private func prettify(_ metadata: Logging.Logger.Metadata) -> String? {
        guard !metadata.isEmpty else {
            return nil
        }

        return metadata
            .sorted(by: \.key)
            .map { "\($0): \($1)" }
            .joined(separator: ", ")
    }
}

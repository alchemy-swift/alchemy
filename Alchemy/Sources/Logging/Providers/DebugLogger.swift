extension Logger {
    public static var debug: Logger {
        Logger(label: "Alchemy", destination: DebugLogger())
    }
}

struct DebugLogger: LogDestination {
    @Env var showSource = false

    func log(payload: LogPayload) {
        let metadataString = prettify(payload.metadata ?? [:]).map { " [\($0)]" } ?? ""

        var _level = " \(payload.level) ".uppercased()
        switch payload.level {
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

        let source = showSource ? " [\(payload.source)] " : ""
        print("  \(_level) \(source)\(payload.message)\(metadataString) \n")
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        guard !metadata.isEmpty else {
            return nil
        }

        return metadata
            .sorted(by: \.key)
            .map { "\($0)=\($1)" }
            .joined(separator: ", ")
    }
}

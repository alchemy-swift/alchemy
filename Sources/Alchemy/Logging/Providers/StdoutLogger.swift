extension Logger {
    public static var stdout: Logger {
        Logger(label: "Alchemy", factory: { StreamLogHandler.standardOutput(label: $0) })
    }

    public static var stderr: Logger {
        Logger(label: "Alchemy", factory: { StreamLogHandler.standardError(label: $0) })
    }
}

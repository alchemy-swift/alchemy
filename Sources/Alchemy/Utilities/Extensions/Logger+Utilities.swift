import Logging

extension Logger {
    func withLevel(_ level: Logger.Level) -> Logger {
        var copy = self
        copy.logLevel = level
        return copy
    }
}

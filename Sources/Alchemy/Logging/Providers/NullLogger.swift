import Logging

extension Logger {
    static var null: Logger {
        Logger(handler: { _ in })
    }
}

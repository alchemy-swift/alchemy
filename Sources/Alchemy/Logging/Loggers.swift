import Foundation

public struct Loggers: Plugin {
    public let `default`: Logger.Identifier?
    public let loggers: [Logger.Identifier: Logger]
    var logLevelOverride: Logger.Level? = nil

    public init(`default`: Logger.Identifier? = nil, loggers: [Logger.Identifier : Logger] = [.default: .alchemyDefault]) {
        self.default = `default`
        self.loggers = loggers
    }

    public func registerServices(in app: Application) {
        for (id, logger) in loggers {
            var logger = logger
            if let logLevelOverride {
                logger.logLevel = logLevelOverride
            }

            app.container.registerSingleton(logger, id: id)
        }

        if let _default = `default` {
            app.container.registerSingleton(Log(_default))
        }
    }
}

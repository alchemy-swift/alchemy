public struct Loggers: Plugin {
    public let `default`: Logger.Identifier?
    public let loggers: [Logger.Identifier: Logger]

    public init(`default`: Logger.Identifier? = nil, loggers: [Logger.Identifier : Logger] = [:]) {
        self.default = `default`
        self.loggers = loggers
    }

    public func registerServices(in app: Application) {
        let logLevel = app.env.logLevel
        for (id, logger) in loggers {
            var logger = logger
            if let logLevel {
                logger.logLevel = logLevel
            }

            app.container.register(logger, id: id).singleton()
        }

        if let _default = `default` ?? loggers.keys.first {
            app.container.register(Log(_default)).singleton()
        }
        
        if !Env.isXcode && Env.isDebug && !Env.isTesting {
            print() // Clear out the console on boot.
        }
    }
}

extension Environment {
    var logLevel: Logger.Level? {
        if let value = CommandLine.value(for: "--log") ?? CommandLine.value(for: "-l"), let level = Logger.Level(rawValue: value) {
            return level
        } else if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"], let level = Logger.Level(rawValue: value) {
            return level
        } else {
            return nil
        }
    }
}

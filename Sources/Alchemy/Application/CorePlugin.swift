import NIO

/// Sets up core application services that other plugins may depend on.
struct CorePlugin: Plugin {
    func registerServices(in app: Application) {

        // 0. Register Environment

        let envName: String?
        if let value = CommandLine.value(for: "--env") ?? CommandLine.value(for: "-e") {
            envName = value
        } else if let value = ProcessInfo.processInfo.environment["APP_ENV"] {
            envName = value
        } else {
            envName = nil
        }

        let env: Environment
        if let envName {
            env = Environment(name: envName)
        } else {
            env = .default
        }

        env.loadVariables()
        app.container.registerSingleton(env)

        // 1. Register Loggers

        let logLevel: Logger.Level?
        if let value = CommandLine.value(for: "--log") ?? CommandLine.value(for: "-l"), let level = Logger.Level(rawValue: value) {
            logLevel = level
        } else if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"], let level = Logger.Level(rawValue: value) {
            logLevel = level
        } else {
            logLevel = nil
        }

        var loggers = app.loggers
        loggers.logLevelOverride = logLevel
        loggers.registerServices(in: app)

        // 2. Register NIO services

        let threads = env.isTesting ? 1 : System.coreCount
        app.container.registerSingleton(MultiThreadedEventLoopGroup(numberOfThreads: threads), as: EventLoopGroup.self)
        app.container.registerSingleton(NIOThreadPool(numberOfThreads: threads))
        app.container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !env.isTesting else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.resolveAssert(EventLoopGroup.self).next()
            }

            return current
        }

        // 3. Register Lifecycle

        app.container.registerSingleton(
            ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: {
                        var logger = Log

                        // ServiceLifecycle is pretty noisy. Let's default it to
                        // logging @ .notice or above, unless the user has set
                        // the default log level to .debug or below.
                        if logger.logLevel > .debug {
                            logger.logLevel = .notice
                        }

                        return logger
                    }(),
                    installBacktrace: !app.container.env.isTesting
                )
            )
        )

        // 4. Register the Application

        app.container.registerSingleton(app)
        app.container.registerSingleton(app, as: Application.self)
    }

    func boot(app: Application) {
        app.container.resolve(NIOThreadPool.self)?.start()
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(EventLoopGroup.self)?.shutdownGracefully()
        try await app.container.resolve(NIOThreadPool.self)?.shutdownGracefully()
    }
}

extension Container {
    public var env: Environment {
        resolveAssert()
    }
}

extension Application {
    public var env: Environment {
        container.env
    }

    public var lifecycle: ServiceLifecycle {
        Container.resolveAssert()
    }
}

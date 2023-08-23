import NIO

/// Sets up core application services that other plugins may depend on.
struct CoreServices: Plugin {
    func registerServices(in app: Application) {

        // 0. Get relevant command line arguments

        let args = CommandLine.arguments
        let envName: String?
        if let index = args.firstIndex(of: "--env"), let value = args[safe: index + 1] {
            envName = value
        } else if let index = args.firstIndex(of: "-e"), let value = args[safe: index + 1] {
            envName = value
        } else if let value = ProcessInfo.processInfo.environment["APP_ENV"] {
            envName = value
        } else {
            envName = nil
        }

        let logLevel: Logger.Level?
        if let index = args.firstIndex(of: "--log"), let value = args[safe: index + 1], let level = Logger.Level(rawValue: value) {
            logLevel = level
        } else if let index = args.firstIndex(of: "-l"), let value = args[safe: index + 1], let level = Logger.Level(rawValue: value) {
            logLevel = level
        } else if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"], let level = Logger.Level(rawValue: value) {
            logLevel = level
        } else {
            logLevel = nil
        }

        // 1. Register Environment

        let env: Environment
        if let envName {
            env = Environment(name: envName)
        } else {
            env = .default
        }

        env.loadVariables()
        app.container.registerSingleton(env)

        // 2. Register Loggers

        if !Env.isXcode {
            print() // Clear out the console on boot.
        }

        var loggers = app.loggers
        loggers.logLevelOverride = logLevel
        loggers.registerServices(in: app)

        // 3. Register NIO services

        let threads = env.isTest ? 1 : System.coreCount
        app.container.registerSingleton(MultiThreadedEventLoopGroup(numberOfThreads: threads), as: EventLoopGroup.self)
        app.container.registerSingleton(NIOThreadPool(numberOfThreads: threads))
        app.container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !env.isTest else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.resolveAssert(EventLoopGroup.self).next()
            }

            return current
        }

        // 4. Register Lifecycle

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
                    installBacktrace: !app.container.env.isTest
                )
            )
        )

        // 5. Register the Application

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

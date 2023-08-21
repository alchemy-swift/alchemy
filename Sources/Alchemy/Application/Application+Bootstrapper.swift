import NIO

/// Sets up core application services that other plugins may depend on.
struct CoreServices: Plugin {
    let app: Application

    func registerServices(in container: Container) {
        let args = CommandLine.arguments

        // 0. Register Logger

        var logger: Logger = .alchemyDefault
        if let index = args.firstIndex(of: "--log"), let value = args[safe: index + 1], let level = Logger.Level(rawValue: value) {
            logger.logLevel = level
        } else if let index = args.firstIndex(of: "-l"), let value = args[safe: index + 1], let level = Logger.Level(rawValue: value) {
            logger.logLevel = level
        } else if let value = ProcessInfo.processInfo.environment["LOG_LEVEL"], let level = Logger.Level(rawValue: value) {
            logger.logLevel = level
        }

        container.registerSingleton(logger)

        // 1. Register Environment

        let env: Environment
        if let index = args.firstIndex(of: "--env"), let value = args[safe: index + 1] {
            env = Environment(name: value)
        } else if let index = args.firstIndex(of: "-e"), let value = args[safe: index + 1] {
            env = Environment(name: value)
        } else if let value = ProcessInfo.processInfo.environment["APP_ENV"] {
            env = Environment(name: value)
        } else {
            env = .default
        }

        container.registerSingleton(env)

        // 2. Register NIO services

        let threads = env.isTest ? 1 : System.coreCount
        container.registerSingleton(MultiThreadedEventLoopGroup(numberOfThreads: threads), as: EventLoopGroup.self)
        container.registerSingleton(NIOThreadPool(numberOfThreads: threads))
        container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !env.isTest else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.resolveAssert(EventLoopGroup.self).next()
            }

            return current
        }

        // 3. Register the Application

        container.registerSingleton(app)
        container.registerSingleton(app, as: Application.self)
    }

    func boot(app: Application) {
        app.container.resolve(NIOThreadPool.self)?.start()
        app.container.resolve(Environment.self)?.loadVariables()
    }

    func shutdownServices(in container: Container) async throws {
        try await container.resolve(EventLoopGroup.self)?.shutdownGracefully()
        try await container.resolve(NIOThreadPool.self)?.shutdownGracefully()
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
}

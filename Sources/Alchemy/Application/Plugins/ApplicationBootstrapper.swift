import NIO

/// Sets up core application services that other plugins may depend on.
struct ApplicationBootstrapper: Plugin {
    func registerServices(in app: Application) {

        // 0. Register Environment

        app.container.register { Environment.createDefault() }.singleton()

        // 1. Register Loggers

        app.loggers.registerServices(in: app)

        // 2. Register NIO services

        app.container.register { MultiThreadedEventLoopGroup(numberOfThreads: $0.coreCount) as EventLoopGroup }.singleton()
        app.container.register { NIOThreadPool(numberOfThreads: $0.coreCount) }.singleton()
        app.container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !container.env.isTesting else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.require(EventLoopGroup.self).next()
            }

            return current
        }

        // 3. Register Lifecycle

        app.container.register { container in
            var logger = container.log

            // ServiceLifecycle is pretty noisy. Let's default it to
            // logging @ .notice or above, unless the user has set
            // the default log level to .debug or below.
            if logger.logLevel > .debug {
                logger.logLevel = .notice
            }

            return ServiceLifecycle(
                configuration: ServiceLifecycle.Configuration(
                    logger: logger,
                    installBacktrace: !container.env.isTesting
                )
            )
        }.singleton()

        // 4. Register the Application

        app.container.register(app).singleton()
        app.container.register(app as Application).singleton()
    }

    func boot(app: Application) {
        app.container.resolve(NIOThreadPool.self)?.start()
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(EventLoopGroup.self)?.shutdownGracefully()
        try await app.container.resolve(NIOThreadPool.self)?.shutdownGracefully()
    }
}

extension Application {
    public var env: Environment {
        container.require()
    }

    public var lifecycle: ServiceLifecycle {
        container.require()
    }
}

extension Container {
    var env: Environment {
        require()
    }

    var log: Logger {
        require()
    }

    fileprivate var coreCount: Int {
        env.isTesting ? 1 : System.coreCount
    }
}

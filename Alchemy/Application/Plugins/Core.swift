import NIO

/// Registers core Alchemy services to an application.
struct Core: Plugin {
    func registerServices(in app: Application) {
        
        // 0. Register Application
        
        app.container.register(app).singleton()
        app.container.register(app as Application).singleton()
        
        // 1. Register Environment

        app.container.register { Environment.createDefault() }.singleton()

        // 2. Register Loggers

        app.loggers.registerServices(in: app)

        // 3. Register NIO services

        app.container.register { MultiThreadedEventLoopGroup(numberOfThreads: $0.coreCount) as EventLoopGroup }.singleton()
        app.container.register { NIOThreadPool.singleton }
        app.container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !container.env.isTesting else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.require(EventLoopGroup.self).next()
            }

            return current
        }

        // 4. Register Lifecycle

        app.container.register { container in
            var logger: Logger = container.require()

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
    }

    func boot(app: Application) {
        app.container.resolve(NIOThreadPool.self)?.start()
    }

    func shutdownServices(in app: Application) async throws {
        try await app.container.resolve(EventLoopGroup.self)?.shutdownGracefully()
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

    fileprivate var coreCount: Int {
        env.isTesting ? 1 : System.coreCount
    }
}

import NIO

/// Sets up core application services that other plugins may depend on.
struct ApplicationBootstrapper: Plugin {
    let app: Application

    func registerServices(in container: Container) {

        // 0. Register app to container

        container.registerSingleton(app)
        container.registerSingleton(app, as: Application.self)

        // 1. Setup Environment

        let env: Environment
        let args = CommandLine.arguments
        if let index = args.firstIndex(of: "--env"), let value = args[safe: index + 1] {
            env = Environment(name: value)
        } else if let index = args.firstIndex(of: "-e"), let value = args[safe: index + 1] {
            env = Environment(name: value)
        } else if let value = ProcessInfo.processInfo.environment["APP_ENV"] {
            env = Environment(name: value)
        } else {
            env = .default
        }

        env.loadVariables()
        container.registerSingleton(env)

        // 2. Setup NIO

        let threads = container.env.isTesting ? 1 : System.coreCount
        container.registerSingleton(MultiThreadedEventLoopGroup(numberOfThreads: threads), as: EventLoopGroup.self)
        container.registerSingleton(NIOThreadPool(numberOfThreads: threads))
        container.register { container in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop, !container.env.isTesting else {
                // With async/await there is no guarantee that you'll
                // be running on an event loop. When one is needed,
                // return a random one for now.
                return container.resolveAssert(EventLoopGroup.self).next()
            }

            return current
        }
    }

    func boot(app: Application) {
        app.container.resolve(NIOThreadPool.self)?.start()
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

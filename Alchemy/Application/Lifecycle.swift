import NIOConcurrencyHelpers
import ServiceLifecycle

/// Manages the startup and shutdown of an Application as well as it's various
/// services and configurations.
public final class Lifecycle {
    typealias Action = () async throws -> Void

    fileprivate var startTasks: [Action] = []
    fileprivate var shutdownTasks: [Action] = []

    let app: Application
    let plugins: [Plugin]

    private var group: ServiceGroup?
    private var services: [Service] = []
    private let lock = NIOLock()

    init(app: Application) {
        self.app = app
        self.plugins = [
            Core(),
            Schedules(),
            EventStreams(),
            app.http,
            app.commands,
            app.filesystems,
            app.databases,
            app.caches,
            app.queues,
        ] + app.plugins
    }

    public func start() async throws {
        app.container.register(self).singleton()

        for plugin in plugins {
            plugin.registerServices(in: app)
        }

        for plugin in plugins {
            try await plugin.boot(app: app)
        }

        for start in startTasks {
            try await start()
        }
    }

    public func shutdown() async throws {
        for shutdown in shutdownTasks.reversed() {
            try await shutdown()
        }

        for plugin in plugins.reversed() {
            try await plugin.shutdownServices(in: app)
        }
    }

    public func onStart(action: @escaping () async throws -> Void) {
        lock.withLock { startTasks.append(action) }
    }

    public func onShutdown(action: @escaping () async throws -> Void) {
        lock.withLock { shutdownTasks.append(action) }
    }

    public func addService(_ service: Service) {
        lock.withLock { services.append(service) }
    }

    public func start(args: [String]? = nil) async throws {
        try await Container.require(Commander.self).runCommand(args: args)
    }

    public func runServices() async throws {
        group = ServiceGroup(
            configuration: ServiceGroupConfiguration(
                services: services.map {
                    .init(
                        service: $0,
                        successTerminationBehavior: .gracefullyShutdownGroup,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    )
                },
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: Log
            )
        )
        try await group?.run()
    }

    public func stop() async {
        await group?.triggerGracefulShutdown()
    }
}

extension Application {
    var lifecycle: Lifecycle {
        container.require()
    }
}

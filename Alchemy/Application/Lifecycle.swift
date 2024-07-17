import NIOConcurrencyHelpers
import ServiceLifecycle

/// Manages the startup and shutdown of an Application as well as it's various
/// services and configurations.
public final class Lifecycle {
    public typealias Action = () async throws -> Void

    private let app: Application
    private let plugins: [Plugin]
    private let lock = NIOLock()
    private var startTasks: [Action] = []
    private var shutdownTasks: [Action] = []
    private var services: [Service] = []
    private var group: ServiceGroup? = nil

    init(app: Application) {
        self.app = app
        self.plugins = [
            Core(),
            app.commands,
            Schedules(),
            EventStreams(),
            app.http,
            app.filesystems,
            app.databases,
            app.caches,
            app.queues,
        ] + app.plugins
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

    public func boot() async throws {
        app.container.register(self).singleton()

        for plugin in plugins {
            try await plugin.boot(app: app)
        }

        for start in startTasks {
            try await start()
        }
        
        (app as? Controller)?.route(app)
        try await app.boot()
    }

    public func shutdown() async throws {
        try await app.shutdown()

        for shutdown in shutdownTasks.reversed() {
            try await shutdown()
        }

        for plugin in plugins.reversed() {
            try await plugin.shutdown(app: app)
        }
    }

    public func stop() async {
        await group?.triggerGracefulShutdown()
    }

    public func onStart(action: @escaping Action) {
        lock.withLock { startTasks.append(action) }
    }

    public func onShutdown(action: @escaping Action) {
        lock.withLock { shutdownTasks.append(action) }
    }

    public func addService(_ service: Service) {
        lock.withLock { services.append(service) }
    }
}

extension Application {
    var lifecycle: Lifecycle {
        container.require()
    }
}

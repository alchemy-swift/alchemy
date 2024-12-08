import NIOConcurrencyHelpers

/// Manages the startup and shutdown of an Application as well as it's various
/// services and configurations.
public final class Lifecycle {
    public typealias Action = () async throws -> Void

    private let app: Application
    private var services: [Service] = []
    private let plugins: [Plugin]
    private var onBoots: [Action] = []
    private var onShutdowns: [Action] = []

    private let lock = NIOLock()
    private var group: ServiceGroup? = nil

    init(app: Application) {
        self.app = app
        self.plugins = [Core()] + app.plugins
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
        for plugin in plugins {
            try await plugin.boot(app: app)
        }

        for action in onBoots {
            try await action()
        }

        try await app.boot()
    }

    public func shutdown() async throws {
        try await app.shutdown()

        for onShutdown in onShutdowns.reversed() {
            try await onShutdown()
        }

        for plugin in plugins.reversed() {
            try await plugin.shutdown(app: app)
        }
    }

    public func stop() async {
        await group?.triggerGracefulShutdown()
    }

    public func onBoot(action: @escaping Action) {
        lock.withLock { onBoots.append(action) }
    }

    public func onShutdown(action: @escaping Action) {
        lock.withLock { onShutdowns.append(action) }
    }

    public func addService(_ service: Service) {
        lock.withLock { services.append(service) }
    }
}

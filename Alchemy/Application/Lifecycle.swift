import ServiceLifecycle

/// Manages the startup and shutdown of an Application as well as it's various
/// services and configurations.
actor Lifecycle {
    typealias Action = () async throws -> Void

    fileprivate var startTasks: [Action] = []
    fileprivate var shutdownTasks: [Action] = []

    let app: Application
    let plugins: [Plugin]

    private var group: ServiceGroup?
    private var services: [ServiceLifecycle.Service] = []

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

    func start() async throws {
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

    func shutdown() async throws {
        for shutdown in shutdownTasks.reversed() {
            try await shutdown()
        }

        for plugin in plugins.reversed() {
            try await plugin.shutdownServices(in: app)
        }
    }

    func onStart(action: @escaping () async throws -> Void) {
        self.startTasks.append(action)
    }

    func onShutdown(action: @escaping () async throws -> Void) {
        self.shutdownTasks.append(action)
    }

    func addService(_ service: ServiceLifecycle.Service) {
        services.append(service)
    }

    func start(args: [String]? = nil) async throws {
        let commander = Container.require(Commander.self)
        commander.setArgs(args)
        let allServices = services + [commander]
        let group = ServiceGroup(
            configuration: ServiceGroupConfiguration(
                services: allServices.map {
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

        self.group = group
        try await group.run()
    }

    func stop() async {
        await group?.triggerGracefulShutdown()
    }
}

extension Application {
    var lifecycle: Lifecycle {
        container.require()
    }
}

extension Container {
    static var lifecycle: Lifecycle {
        require()
    }

    public static func onStart(action: @escaping () async throws -> Void) {
        Task { await lifecycle.onStart(action: action) }
    }

    public static func onShutdown(action: @escaping () async throws -> Void) {
        Task { await lifecycle.onShutdown(action: action) }
    }

    public static func addService(_ service: ServiceLifecycle.Service) {
        Task { await lifecycle.addService(service) }
    }
}

import NIO

/// The core type for an Alchemy application. Implement this & it's
/// `boot` function, then add the `@main` attribute to mark it as
/// the entrypoint for your application.
///
///     @main
///     struct App: Application {
///         func boot() {
///             get("/hello") { _ in
///                 "Hello, world!"
///             }
///         }
///     }
///
public protocol Application {
    /// Setup your application here. Called after all services are loaded.
    func boot() throws

    /// Required empty initializer.
    init()

    // MARK: Configs

    /// The cache configuration of the application.
    var caches: Caches { get }

    /// The core configuration of the application.
    var configuration: Configuration { get }

    /// The database configuration of the application.
    var databases: Databases { get }

    /// The filesystem configuration of the application.
    var filesystems: Filesystems { get }

    /// The loggers of you application.
    var loggers: Loggers { get }

    /// The queue configuration of the application.
    var queues: Queues { get }

    /// The default plugins to use for this application.
    var defaultPlugins: [Plugin] { get }
}

extension Application {
    public var caches: Caches { Caches() }
    public var configuration: Configuration { Configuration() }
    public var databases: Databases { Databases() }
    public var filesystems: Filesystems { Filesystems() }
    public var loggers: Loggers { Loggers() }
    public var queues: Queues { Queues() }

    public var defaultPlugins: [Plugin] {
        [
            EventsPlugin(),
            RoutingPlugin(),
            SchedulingPlugin(),
            Commands(),
            Clients(),
            filesystems,
            databases,
            caches,
            queues,
        ]
    }

    public func boot() { /* default to no-op */ }

    public func run() async throws {
        registerServices()
        try await Lifecycle.start()
        try boot()
        try await start()
    }

    /// Register core services to the application container `Container.default`.
    public func registerServices() {

        // 0. Setup the main Container.

        Container.main = Container()

        // 1. Boot CoreServices.

        let core = CoreServices()
        core.registerServices(in: self)
        core.boot(app: self)

        // 2. Register Plugins.


        let defaultPlugins = defaultPlugins
        defaultPlugins.forEach { $0.registerServices(in: self) }
        let userPlugins = configuration.plugins()
        userPlugins.forEach { $0.registerServices(in: self) }

        // 3. Register Plugin Lifecyle events.

        lifecycle.register(
            label: core.label,
            start: .none,
            shutdown: .async { try await core.shutdownServices(in: self) }
        )

        for plugin in defaultPlugins + userPlugins {
            lifecycle.register(
                label: plugin.label,
                start: .async { try await plugin.boot(app: self) },
                shutdown: .async { try await plugin.shutdownServices(in: self) }
            )
        }
    }

    /// Setup and launch this application. By default it serves, see `Launch`
    /// for subcommands and options. This is so the app can be started with
    /// @main.
    public static func main() async throws {
        try await Self().run()
    }
}

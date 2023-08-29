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
public protocol Application: Router {
    /// Create an instance of this Application.
    init()

    /// Setup your application here. Called after all services are loaded.
    func boot() throws

    /// Setup any scheduled tasks in your application here.
    func schedule(on schedule: Scheduler)

    // MARK: Configuration

    /// The core configuration of the application.
    var configuration: Configuration { get }

    /// The cache configuration of the application.
    var caches: Caches { get }

    /// The database configuration of the application.
    var databases: Databases { get }

    /// The filesystem configuration of the application.
    var filesystems: Filesystems { get }

    /// The loggers of you application.
    var loggers: Loggers { get }

    /// The queue configuration of the application.
    var queues: Queues { get }
}

extension Application {
    public var caches: Caches { Caches() }
    public var configuration: Configuration { Configuration() }
    public var databases: Databases { Databases() }
    public var filesystems: Filesystems { Filesystems() }
    public var loggers: Loggers { Loggers() }
    public var queues: Queues { Queues() }

    public func boot() { /* default to no-op */ }
    public func schedule(on schedule: Scheduler) { /* default to no-op */ }

    public func run() async throws {
        setup()
        try await Lifecycle.start()
        try await start()
    }

    public func setup() {

        // 1. Register Core Services.

        let bootstrap = ApplicationBootstrapper()
        bootstrap.registerServices(in: self)
        bootstrap.boot(app: self)

        lifecycle.register(
            label: bootstrap.label,
            start: .none,
            shutdown: .async { try await bootstrap.shutdownServices(in: self) }
        )

        // 2. Register Plugins.

        for plugin in configuration.defaultPlugins(self) + configuration.plugins() {
            plugin.registerServices(in: self)
            lifecycle.register(
                label: plugin.label,
                start: .async { try await plugin.boot(app: self) },
                shutdown: .async { try await plugin.shutdownServices(in: self) }
            )
        }

        // 3. Register Application.boot to Lifecycle

        lifecycle.register(
            label: "Application Boot",
            start: .sync { try boot() },
            shutdown: .none
        )
    }

    /// Starts the application with the given arguments.
    public func start(_ args: String...) async throws {
        try await start(args: args.isEmpty ? nil : args)
    }

    /// Starts the application with the given arguments.
    public func start(args: [String]? = nil) async throws {
        try await commander.start(args: args)
    }

    public func stop() async throws {
        try await Lifecycle.shutdown()
    }

    /// Setup and launch this application. By default it serves, see `Launch`
    /// for subcommands and options. This is so the app can be started with
    /// @main.
    public static func main() async throws {
        try await Self().run()
    }
}


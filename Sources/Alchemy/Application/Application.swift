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

    /// Setup your application here. Called after all services are registered.
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
    /// The main application container.
    public var container: Container { .main }
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
        try boot()
        try await start()
    }

    public func setup() {

        // 0. Register the Application

        container.register(self).singleton()
        container.register(self as Application).singleton()

        // 1. Register core Plugin services.

        let core = ApplicationPlugin()
        core.registerServices(in: self)

        // 2. Register other Plugin services.

        let plugins = configuration.defaultPlugins(self) + configuration.plugins()
        for plugin in plugins {
            plugin.registerServices(in: self)
        }

        // 3. Register all Plugins with lifecycle.

        for plugin in [core] + plugins {
            lifecycle.register(
                label: plugin.label,
                start: .async {
                    try await plugin.boot(app: self)
                },
                shutdown: .async {
                    try await plugin.shutdownServices(in: self)
                },
                shutdownIfNotStarted: true
            )
        }
    }

    /// Starts the application with the given arguments.
    public func start(_ args: String..., wait: Bool = true) async throws {
        try await start(args: args.isEmpty ? nil : args, wait: wait)
    }

    /// Starts the application with the given arguments.
    public func start(args: [String]? = nil, wait: Bool = true) async throws {
        try await lifecycle.start()
        try await commander.start(args: args, wait: wait)
    }

    public func stop() async throws {
        try await lifecycle.shutdown()
    }

    /// Setup and launch this application. By default it serves, see `Launch`
    /// for subcommands and options. This is so the app can be started with
    /// @main.
    public static func main() async throws {
        try await Self().run()
    }
}

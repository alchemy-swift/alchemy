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
    /// The configuration of the underlying application.
    var configuration: Configuration { get }

    /// Setup your application here. Called after all services are loaded.
    func boot() throws

    /// Required empty initializer.
    init()
}

extension Application {
    public var configuration: Configuration { .default }

    private var defaultPlugins: [Plugin] {
        [
            LifecyclePlugin(),
            EventsPlugin(),
            RoutingPlugin(),
            SchedulingPlugin(),
            Commands(),
            Clients(),
        ]
    }

    public func boot() { /* no-op */ }

    public func run() throws {
        setupServices()
        try boot()
        try lifecycle.startAndWait()
    }

    /// Register core services to the application container `Container.default`.
    public func setupServices() {

        // 0. Setup the main Container.

        Container.main = Container()

        // 1. Bootstrap core services.

        let core = ApplicationBootstrapper(app: self)
        core.registerServices(in: container)

        // 2. Register Plugins.

        let plugins = defaultPlugins + configuration.plugins
        plugins.forEach { $0.registerServices(in: container) }

        // 3. Register Plugin Lifecyle events.

        for plugin in [core] + plugins {
            lifecycle.register(
                label: plugin.label,
                start: .async { try await plugin.boot(app: self) },
                shutdown: .async { try await plugin.shutdownServices(in: container) }
            )
        }

        // 4. Register `start()`.

        lifecycle.register(label: "\(Self.self)", start: .async { try await start() }, shutdown: .none)
    }

    /// Setup and launch this application. By default it serves, see `Launch`
    /// for subcommands and options. This is so the app can be started with
    /// @main.
    public static func main() throws {
        try Self().run()
    }
}

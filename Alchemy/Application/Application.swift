/// The core type for an Alchemy application.
///
///     @Application
///     struct App {
///
///         @GET("/hello")
///         func sayHello(name: String) -> String {
///             "Hello, \(name)!"
///         }
///     }
///
public protocol Application: Router {
    /// The container in which all services of this application are registered.
    var container: Container { get }
    /// Any custom plugins of this application.
    var plugins: [Plugin] { get }
    
    init()
    
    /// Boots the app's dependencies. Don't override the default for this unless
    /// you want to prevent default Alchemy services from loading.
    func bootPlugins() async throws
    /// Setup your application here. Called after all services are registered.
    func boot() throws
    
    // MARK: Default Plugin Configurations
    
    /// This application's HTTP configuration.
    var http: HTTPConfiguration { get }
    /// This application's filesystems.
    var filesystems: Filesystems { get }
    /// This application's databases.
    var databases: Databases { get }
    /// The application's caches.
    var caches: Caches { get }
    /// The application's job queues.
    var queues: Queues { get }
    /// The application's custom commands.
    var commands: Commands { get }
    /// The application's loggers.
    var loggers: Loggers { get }
    
    /// Setup any scheduled tasks in your application here.
    func schedule(on schedule: Scheduler)
}

// MARK: Defaults

public extension Application {
    var container: Container { .main }
    var plugins: [Plugin] { [] }
    
    func bootPlugins() async throws {
        let alchemyPlugins: [Plugin] = [
            Core(),
            Schedules(),
            EventStreams(),
            http,
            commands,
            filesystems,
            databases,
            caches,
            queues,
        ]

        let allPlugins = alchemyPlugins + plugins
        for plugin in alchemyPlugins + plugins {
            plugin.registerServices(in: self)
        }

        Container.onStart {
            for plugin in allPlugins {
                try await plugin.boot(app: self)
            }
        }

        Container.onShutdown {
            for plugin in allPlugins.reversed() {
                try await plugin.shutdownServices(in: self)
            }
        }
    }

    func boot() throws {
        //
    }

    func bootRouter() {
        (self as? Controller)?.route(self)
    }

    // MARK: Plugin Defaults
    
    var http: HTTPConfiguration { HTTPConfiguration() }
    var commands: Commands { [] }
    var databases: Databases { Databases() }
    var caches: Caches { Caches() }
    var queues: Queues { Queues() }
    var filesystems: Filesystems { Filesystems() }
    var loggers: Loggers { Loggers() }
    
    func schedule(on schedule: Scheduler) {
        //
    }
}

import ServiceLifecycle

// MARK: Running

public extension Application {
    func run() async throws {
        do {
            try await bootPlugins()
            try boot()
            bootRouter()
            try await start()
        } catch {
            commander.exit(error: error)
        }
    }
    
    /// Starts the application with the given arguments.
    func start(_ args: String..., waitOrShutdown: Bool = true) async throws {
        try await start(args: args.isEmpty ? nil : args, waitOrShutdown: waitOrShutdown)
    }

    /// Starts the application with the given arguments.
    ///
    /// @MainActor ensures that calls to `wait()` doesn't block an `EventLoop`.
    @MainActor
    func start(args: [String]? = nil, waitOrShutdown: Bool = true) async throws {

        // 0. Add service

        Container.main
            .lifecycleServices
            .append(
                ApplicationService(
                    args: args,
                    waitOrShutdown: waitOrShutdown,
                    app: self
                )
            )

        // 1. Start the application lifecycle.

        try await serviceGroup.run()
    }

    /// Stops the application.
    func stop() async {
        await serviceGroup.triggerGracefulShutdown()
    }

    // @main support
    static func main() async throws {
        try await Self().run()
    }
}

private actor ApplicationService: ServiceLifecycle.Service {
    var args: [String]? = nil
    var waitOrShutdown: Bool = true
    let app: Application

    init(args: [String]? = nil, waitOrShutdown: Bool, app: Application) {
        self.args = args
        self.waitOrShutdown = waitOrShutdown
        self.app = app
    }

    func run() async throws {

        // 0. Parse and run a `Command` based on the application arguments.

        let command = try await app.commander.runCommand(args: args)
        guard waitOrShutdown else { return }
        
        // 1. Wait for lifecycle or immediately shut down depending on if the
        //    command should run indefinitely.

        if !command.runUntilStopped {
            await app.stop()
        }

        // 2. this is required to not throw service lifecycle errors

        try await gracefulShutdown()
    }
}

fileprivate extension ParsableCommand {
    var runUntilStopped: Bool {
        (Self.self as? Command.Type)?.runUntilStopped ?? false
    }
}

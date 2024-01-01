/// The core type for an Alchemy application. Implement this & it's
/// `boot` function, then add the `@main` attribute to mark it as
/// the entrypoint for your application.
///
///     @main
///     final class App: Application {
///         func boot() {
///             get("/hello") { _ in
///                 "Hello, world!"
///             }
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
    func bootPlugins()
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
    
    func bootPlugins() {
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
        
        for plugin in alchemyPlugins + plugins {
            plugin.register(in: self)
        }
    }

    func boot() throws {
        //
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

// MARK: Running

public extension Application {
    func run() async throws {
        do {
            bootPlugins()
            try boot()
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

        // 0. Start the application lifecycle.

        try await lifecycle.start()

        // 1. Parse and run a `Command` based on the application arguments.

        let command = try await commander.runCommand(args: args)
        guard waitOrShutdown else { return }

        // 2. Wait for lifecycle or immediately shut down depending on if the
        //    command should run indefinitely.
        
        if command.runUntilStopped {
            wait()
        } else {
            try await stop()
        }
    }

    /// Waits indefinitely for the application to be stopped.
    func wait() {
        lifecycle.wait()
    }

    /// Stops the application.
    func stop() async throws {
        try await lifecycle.shutdown()
    }

    // @main support
    static func main() async throws {
        try await Self().run()
    }
}

fileprivate extension ParsableCommand {
    var runUntilStopped: Bool {
        (Self.self as? Command.Type)?.runUntilStopped ?? false
    }
}

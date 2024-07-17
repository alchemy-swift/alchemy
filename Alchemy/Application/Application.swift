import HummingbirdCore

/// The core type for an Alchemy application.
///
/// ```swift
/// @Application
/// struct App {
///     
///     @GET("/hello")
///     func hello(name: String) -> String {
///         "Hello, \(name)!"
///     }
/// }
/// ```
public protocol Application: Router {
    /// The container in which all services of this application are registered.
    var container: Container { get }
    /// Any custom plugins of this application.
    var plugins: [Plugin] { get }
    /// Build the hummingbird server
    var server: HTTPServerBuilder { get }

    init()
    
    /// Setup your application here. Called after all services are registered.
    func boot() throws
    /// Optional shutdown logic here.
    func shutdown() throws

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
    var caches: Caches { Caches() }
    var commands: Commands { [] }
    var container: Container { .main }
    var databases: Databases { Databases() }
    var filesystems: Filesystems { Filesystems() }
    var http: HTTPConfiguration { HTTPConfiguration() }
    var loggers: Loggers { Loggers() }
    var plugins: [Plugin] { [] }
    var queues: Queues { Queues() }
    var server: HTTPServerBuilder { .http1() }

    func boot() throws {}
    func shutdown() throws {}
    func schedule(on schedule: Scheduler) {}
}

// MARK: Running

extension Application {
    /// @main support
    public static func main() async throws {
        let app = Self()
        do {
            try await app.willRun()
            try await app.run()
            try await app.didRun()
        } catch {
            app.commander.exit(error: error)
        }
    }

    /// Runs the application with the given arguments.
    public func run(_ args: String...) async throws {
        try await run(args)
    }

    /// Runs the application with the given arguments.
    public func run(_ args: [String]) async throws {
        try await commander.run(args: args.isEmpty ? nil : args)
    }

    /// Sets up the app for running.
    public func willRun() async throws {
        let lifecycle = Lifecycle(app: self)
        try await lifecycle.boot()
        (self as? Controller)?.route(self)
        try boot()
    }

    /// Any cleanup after the app finishes running.
    public func didRun() async throws {
        try shutdown()
        try await lifecycle.shutdown()
    }

    /// Stops a currently running application.
    public func stop() async {
        await lifecycle.stop()
    }
}

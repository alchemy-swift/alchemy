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
    /// Your app's custom plugins.
    var plugins: [Plugin] { get }
    /// Your app's custom commands.
    var commands: [Command.Type] { get }
    /// Your app's custom jobs.
    var jobs: [Job.Type] { get }
    /// Your app's migrations
    var migrations: [Migration] { get }
    /// Your app's database seeders
    var seeders: [Seeder] { get }
    /// Build the hummingbird server
    var server: HTTPServerBuilder { get }

    init()

    /// Setup logic for your app - called before running your app.
    func boot() async throws
    /// Tear down logic for your app - called when the app stops with no error.
    func shutdown() async throws
}

// MARK: Running

extension Application {
    /// @main support
    public static func main() async throws {
        try await Self().start()
    }

    /// Start the app. This boots the app, runs a command based on arguments,
    /// and runs any cleanup.
    public func start() async throws {
        do {
            try await willRun()
            try await run()
            try await didRun()
        } catch {
            didError(error)
        }
    }

    /// Stops a currently running application. The `Application` will handle this
    /// as though it were sent a `SIGINT`.
    public func stop() async {
        await Life.stop()
    }

    /// Runs the application with the given arguments.
    public func run(_ args: String...) async throws {
        try await run(args)
    }

    /// Runs the application with the given arguments.
    public func run(_ args: [String]) async throws {
        try await CMD.run(args: args.isEmpty ? nil : args)
    }

    /// Sets up the app for running.
    public func willRun() async throws {
        Main = self
        try await Life.boot()
    }

    /// Any cleanup after the app finishes running.
    public func didRun() async throws {
        try await Life.shutdown()
    }

    /// Any cleanup after the app finishes with an error.
    public func didError(_ error: Error) {
        CMD.exit(error: error)
    }
}

// MARK: Defaults

public extension Application {
    var plugins: [Plugin] { [] }
    var commands: [Command.Type] { [] }
    var jobs: [Job.Type] { [] }
    var migrations: [Migration] { [] }
    var seeders: [Seeder] { [] }
    var server: HTTPServerBuilder { .http1() }
    func boot() async throws {}
    func shutdown() async throws {}
}

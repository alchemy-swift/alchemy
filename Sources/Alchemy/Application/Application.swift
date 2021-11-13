/// The core type for an Alchemy application. Implement this & it's
/// `boot` function, then add the `@main` attribute to mark it as
/// the entrypoint for your application.
///
/// ```swift
/// @main
/// struct App: Application {
///     func boot() {
///         get("/hello") { _ in
///             "Hello, world!"
///         }
///         ...
///     }
/// }
/// ```
public protocol Application {
    /// Any custom commands provided by your application.
    var commands: [Command.Type] { get }
    
    /// Called before any launch command is run. Called after any
    /// environment and services are loaded.
    func boot() throws
    
    /// Register your custom services to the application's service container
    /// here
    func services(container: Container)
    
    /// Schedule any recurring jobs or tasks here.
    func schedule(schedule: Scheduler)
    
    /// Required empty initializer.
    init()
}

// No-op defaults
extension Application {
    public var commands: [Command.Type] { [] }
    public func services(container: Container) {}
    public func schedule(schedule: Scheduler) {}
}

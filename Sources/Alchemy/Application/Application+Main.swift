import Hummingbird
import Lifecycle
import LifecycleNIOCompat

extension Application {
    /// The current application for easy access.
    public static var current: Self { Container.resolveAssert() }
    /// The application's lifecycle.
    public var lifecycle: ServiceLifecycle { Container.resolveAssert() }
    /// The underlying hummingbird application.
    public var _application: HBApplication { Container.resolveAssert() }
    /// The underlying router.
    var router: Router { Container.resolveAssert() }
    /// The underlying scheduler.
    var scheduler: Scheduler { Container.resolveAssert() }
    
    /// Setup and launch this application. By default it serves, see `Launch`
    /// for subcommands and options. Call this in the `main.swift`
    /// of your project.
    public static func main() throws {
        let app = Self()
        try app.setup()
        try app.start()
        app.wait()
    }
    
    /// Sets up this application for running.
    public func setup(testing: Bool = Env.isRunningTests) throws {
        bootServices(testing: testing)
        try boot()
        services(container: .main)
        schedule(schedule: Container.resolveAssert())
    }
    
    /// Starts the application with the given arguments.
    public func start(_ args: String...) throws {
        try start(args: args)
    }
    
    /// Blocks until the application receives a shutdown signal.
    public func wait() {
        lifecycle.wait()
    }
    
    /// Stops your application from running.
    public func stop() throws {
        var shutdownError: Error? = nil
        let semaphore = DispatchSemaphore(value: 0)
        lifecycle.shutdown {
            shutdownError = $0
            semaphore.signal()
        }
        
        semaphore.wait()
        if let shutdownError = shutdownError {
            throw shutdownError
        }
    }
    
    public func start(args: [String]) throws {
        // When running tests, don't use the command line args as the default;
        // they are irrelevant to running the app and may contain a bunch of
        // options that will cause `ParsableCommand` parsing to fail.
        let fallbackArgs = Env.isRunningTests ? [] : Array(CommandLine.arguments.dropFirst())
        Launch.customCommands.append(contentsOf: commands)
        Launch.main(args.isEmpty ? fallbackArgs : args)
        
        var startupError: Error? = nil
        let semaphore = DispatchSemaphore(value: 0)
        lifecycle.start {
            startupError = $0
            semaphore.signal()
        }
        
        semaphore.wait()
        if let startupError = startupError {
            throw startupError
        }
    }
}

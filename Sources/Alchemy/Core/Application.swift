import Fusion
import Lifecycle
import LifecycleNIOCompat
import Logging
import NIO
import NIOHTTP1

/// The core type for an Alchemy application. Implement this & it's
/// `setup` function, then call `MyApplication.launch()` in your
/// `main.swift`.
///
/// ```swift
/// // MyApplication.swift
/// struct App: Application {
///     func setup() {
///         self.get("/hello") { _ in
///             "Hello, world!"
///         }
///         ...
///     }
/// }
///
/// // main.swift
/// App.launch()
/// ```
public protocol Application {
    /// Called before any launch command is run. Called AFTER any
    /// environment is loaded and the global
    /// `MultiThreadedEventLoopGroup` is set. Called on an event loop,
    /// so `Services.eventLoop` is available for use if needed.
    func setup()
    
    /// Required empty initializer.
    init()
}

/// An abstraction of what this Alchemy program should do when it
/// launches.
protocol Runner {
    /// Register any tasks to the current lifecyle.
    ///
    /// - Parameter lifecycle: The lifecycle of the program.
    func register(lifecycle: ServiceLifecycle)
}

extension Application {
    /// Lifecycle logs quite a bit by default, this quiets it's `info`
    /// level logs by default. To output messages lower than `notice`,
    /// you can override this property to `.info` or lower.
    public var lifecycleLogLevel: Logger.Level { .notice }
    
    /// Launch this application. By default it serves, see `Launch`
    /// for subcommands and options. Call this in the `main.swift`
    /// of your project.
    public static func main() {
        Launch<Self>.main()
    }
    
    /// Launch the application with the provided runner. It will setup
    /// core services, call `self.setup()`, and then it's behavior
    /// will be defined by the runner.
    ///
    /// - Parameter runner: The runner that defines what the
    ///   application does when it's launched.
    /// - Throws: Any error that may be encountered in booting the
    ///   application.
    func launch(_ runner: Runner) throws {
        // Create app lifecycle
        var lifecycleLogger = Log.logger
        lifecycleLogger.logLevel = lifecycleLogLevel
        let lifecycle = ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: lifecycleLogger,
                installBacktrace: true
            )
        )
        
        // Boot all services
        lifecycle.register(
            label: "AlchemyCore",
            start: .sync { Services.bootstrap(lifecycle: lifecycle) },
            shutdown: .sync(Services.shutdown)
        )
        
        // Setup app
        lifecycle.register(
            label: "\(Self.self)",
            start: .eventLoopFuture {
                Services.eventLoopGroup.next()
                    // Run setup
                    .submit(self.setup)
            },
            shutdown: .none
        )
        
        runner.register(lifecycle: lifecycle)
        
        // Start the lifecycle
        try lifecycle.startAndWait()
    }
}

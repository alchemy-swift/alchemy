import Fusion
import Lifecycle
import LifecycleNIOCompat
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

extension Application {
    /// Launch the application with the provided runner. It will setup
    /// core services, call `self.setup()`, and then it's behavior
    /// will be defined by the runner.
    ///
    /// - Parameter runner: The runner that defines what the
    ///   application does when it's launched.
    /// - Throws: Any error that may be encountered in booting the
    ///   application.
    func launch(_ runner: Runner) throws {
        let lifecycle = ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: Log.logger,
                installBacktrace: true
            )
        )
        
        lifecycle.register(
            label: "AlchemyCore",
            start: .sync { Services.bootstrap(lifecycle: lifecycle) },
            shutdown: .sync(Services.shutdown)
        )
        
        lifecycle.register(
            label: "\(Self.self)",
            start: .eventLoopFuture {
                Services.eventLoopGroup.next()
                    // Run setup
                    .submit(self.setup)
                    // Start the runner
                    .flatMap(runner.start)
            },
            shutdown: .eventLoopFuture(runner.shutdown)
        )
        
        try lifecycle.startAndWait()
    }
}

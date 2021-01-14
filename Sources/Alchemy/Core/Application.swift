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

/// The parameters for what the application should do on startup.
/// Currently can either `serve` or `migrate`.
enum StartupArgs {
    /// Serve to a specific socket. Routes using the singleton
    /// `HTTPRouter`.
    case serve(socket: Socket)
    
    /// Migrate using any migrations added to Services.db. `rollback`
    /// indicates whether all new migrations should be run in a new
    /// batch (`false`) or if the latest batch should be rolled
    /// back (`true`).
    case migrate(rollback: Bool = false)
}

extension Application {
    /// Launch the application with the provided startup arguments. It
    /// will either serve or migrate.
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
            label: "AlchemyCoreServices",
            start: .sync { Services.bootstrap(lifecycle: lifecycle) },
            shutdown: .sync(Services.shutdown)
        )
        
        lifecycle.register(
            label: "AlchemySetup",
            start: .sync { try Services.eventLoopGroup.next().submit(self.setup).wait() },
            shutdown: .sync {}
        )
        
        lifecycle.register(
            label: "\(Self.self)",
            start: .eventLoopFuture(runner.start),
            shutdown: .eventLoopFuture(runner.shutdown)
        )
        
        try lifecycle.startAndWait()
    }
}

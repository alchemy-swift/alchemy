import Fusion
import Lifecycle
import LifecycleNIOCompat
import NIO
import NIOHTTP1

/// The core type for an Alchemy application. Implement this & it's `setup` function, then call
/// `MyApplication.launch()` in your `main.swift`.
///
/// ```
/// // MyApplication.swift
/// struct MyApplication: Application {
///     @Inject router: Router
///
///     func setup() {
///         self.router.on(.GET, "/hello") { _ in
///             return "Hello, world!"
///         }
///         ...
///     }
/// }
///
/// // main.swift
/// MyApplication.launch()
/// ```
public protocol Application {
    /// Called before any launch command is run. Called AFTER any environment is
    /// loaded and the global `MultiThreadedEventLoopGroup` is set. Called on an
    /// event loop, so `Loop.current` is available for use if needed.
    func setup()
    
    /// Required empty initializer.
    init()
}

/// The parameters for what the application should do on startup. Currently
/// can either `serve` or `migrate`.
enum StartupArgs {
    /// Serve to a specific socket. Routes using the singleton `HTTPRouter`.
    case serve(socket: Socket)
    
    /// Migrate using any migrations added to Services.db. `rollback` indicates
    /// whether all new migrations should be run in a new batch (`false`) or if
    /// the latest batch should be rolled back (`true`).
    case migrate(rollback: Bool = false)
}

extension Application {
    /// Launch the application with the provided startup arguments. It will
    /// either serve or migrate.
    ///
    /// - Parameter args: what the application should do when it's launched.
    /// - Throws: any error that may be encountered in booting the application.
    func launch(_ args: StartupArgs) throws {
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
        
        let runner: Runner = {
            switch args {
            case .migrate(let rollback):
                return Migrator(rollback: rollback)
            case .serve(let socket):
                return Server(socket: socket)
            }
        }()
        
        lifecycle.register(
            label: "\(Self.self)",
            start: .eventLoopFuture(runner.start),
            shutdown: .eventLoopFuture(runner.shutdown)
        )
        
        try lifecycle.startAndWait()
    }
}

/// An abstraction of an Alchemy program to run.
private protocol Runner {
    /// Start running.
    ///
    /// - Returns: A future indicating that running has finished.
    func start() -> EventLoopFuture<Void>
    
    /// Stop running, if possible.
    ///
    /// - Returns: A future indicating that shut down has finished.
    func shutdown() -> EventLoopFuture<Void>
}

/// Runs a HTTP server, listening on a socket and routing incoming requests to `Services.router`.
/// Server is the default `Runner` of an Alchemy application.
private final class Server: Runner {
    /// The socket to bind to.
    private let socket: Socket
    
    /// A channel representing the connection to the socket of this server.
    private var channel: Channel?
    
    /// Create a new server that will bind to the given socket.
    ///
    /// - Parameter socket: The socket this server will bind to and listen at.
    init(socket: Socket) {
        self.socket = socket
    }

    // MARK: Runner
    
    func start() -> EventLoopFuture<Void> {
        // Much of this is courtesy of [apple/swift-nio-examples](
        // https://github.com/apple/swift-nio-examples/tree/main/http2-server/Sources/http2-server)
        func childChannelInitializer(
            channel: Channel
        ) -> EventLoopFuture<Void> {
            channel.pipeline
                .configureHTTPServerPipeline(withErrorHandling: true)
                .flatMap { channel.pipeline
                    .addHandler(HTTPHandler(responder: HTTPRouterResponder()))
                }
        }

        let serverBootstrap = ServerBootstrap(group: Services.eventLoopGroup)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer(channel:))

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        let channel = { () -> EventLoopFuture<Channel> in
            switch socket {
            case .ip(let host, let port):
                return serverBootstrap.bind(host: host, port: port)
            case .unix(let path):
                return serverBootstrap.bind(unixDomainSocketPath: path)
            }
        }()
        
        return channel
            .flatMap { boundChannel in
                self.channel = boundChannel
                guard let channelLocalAddress = boundChannel.localAddress else {
                    fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
                }
                
                Log.info("[Server] started and listening on \(channelLocalAddress).")
                return boundChannel.closeFuture
            }
    }
    
    func shutdown() -> EventLoopFuture<Void> {
        self.channel?.close() ?? Services.eventLoopGroup.future()
    }
}

/// Run migrations on `Services.db`, optionally rolling back the latest batch.
private struct Migrator: Runner {
    /// Indicates whether migrations should be run (`false`) or rolled back (`true`).
    let rollback: Bool
    
    // MARK: Runner
    
    func start() -> EventLoopFuture<Void> {
        Services.eventLoopGroup
            .next()
            .flatSubmit(self.rollback ? Services.db.rollbackMigrations : Services.db.migrate)
    }
    
    func shutdown() -> EventLoopFuture<Void> {
        .new()
    }
}

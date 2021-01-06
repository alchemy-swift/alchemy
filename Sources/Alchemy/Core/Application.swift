/// Much of this is courtesy of [apple/swift-nio-examples](
/// https://github.com/apple/swift-nio-examples/tree/main/http2-server/Sources/http2-server)
import Fusion
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
    /// either `serve` or `migrate`.
    ///
    /// - Parameter args: what the application should do when it's launched.
    /// - Throws: any error that may be encountered in booting the application.
    func launch(_ args: StartupArgs) throws {
        // Bootstrap core Alchemy services.
        Services.bootstrap()
        
        // First, run `setup()` on an `EventLoop`.
        let setup = Services.eventLoopGroup.next().submit(self.setup)
            
        switch args {
        case .migrate(let rollback):
            // Migrations need to be run on an `EventLoop`.
            try setup.flatMap { self.migrate(rollback: rollback) }
                .wait()
            Log.info("Migrations finished!")
        case .serve(let socket):
            try setup.wait()
            try self.startServing(socket: socket, group: Services.eventLoopGroup)
        }
        
        try Services.shutdown()
    }
    
    /// Run migrations on `Services.db`, optionally rolling back the latest
    /// batch.
    ///
    /// - Parameter rollback: if true, the latest batch of migrations will be
    ///                       rolled back
    /// - Returns: an `EventLoopFuture<Void>` that completes when the migrations
    ///            are finished.
    private func migrate(rollback: Bool) -> EventLoopFuture<Void> {
        rollback ? Services.db.rollbackMigrations() : Services.db.migrate()
    }
    
    /// Start serving at the given target. Routing is handled by the singleton `HTTPRouter`.
    ///
    /// - Note: this function never unblocks for the lifecycle of the server.
    /// - Parameters:
    ///   - socket: the socket where the server should bind (listen for requests at).
    ///   - group: a `MultiThreadedEventLoopGroup` for fetching `EventLoop`s to handle requests on.
    /// - Throws: any errors encountered when bootstrapping the server.
    private func startServing(socket: Socket, group: EventLoopGroup) throws {
        func childChannelInitializer(
            channel: Channel
        ) -> EventLoopFuture<Void> {
            channel.pipeline
                .configureHTTPServerPipeline(withErrorHandling: true)
                .flatMap { channel.pipeline
                    .addHandler(HTTPHandler(responder: HTTPRouterResponder()))
                }
        }

        let serverBootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions
                    .socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer(channel:))

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(
                ChannelOptions
                    .socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        let channel = try { () -> Channel in
            switch socket {
            case .ip(let host, let port):
                return try serverBootstrap.bind(host: host, port: port).wait()
            case .unix(let path):
                return try serverBootstrap.bind(unixDomainSocketPath: path)
                    .wait()
            }
        }()

        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        
        Log.info("Server started and listening on \(channelLocalAddress).")

        // This will never unblock as we don't close the ServerChannel
        try channel.closeFuture.wait()
    }
}

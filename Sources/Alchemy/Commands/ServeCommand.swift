import ArgumentParser
import NIO

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct ServeCommand<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = "127.0.0.1"
    /// The port to serve at. Defaults to `8080`.
    @Option var port = 8080
    /// The unix socket to serve at. If this is provided, the host and
    /// port will be ignored.
    @Option var unixSocket: String?
    /// The number of Queue workers that should be kicked off in
    /// this process. Defaults to `0`.
    @Option var workers: Int = 0
    /// Should the scheduler run in process, scheduling any recurring
    /// work. Defaults to `false`.
    @Flag var schedule: Bool = false
    
    // MARK: ParseableCommand
    
    func run() throws {
        try A().launch(self)
    }
}

/// Runs a HTTP server, listening on a socket and routing incoming
/// requests to `Services.router`.
extension ServeCommand: Runner {
    // The socket that the server will bind to.
    private var socket: Socket {
        if let unixSocket = unixSocket {
            return .unix(path: unixSocket)
        } else {
            return .ip(host: host, port: port)
        }
    }
    
    func register(lifecycle: ServiceLifecycle) {
        var channel: Channel?
        lifecycle.register(
            label: "Serve",
            start: .eventLoopFuture { self.start().map { channel = $0 } },
            shutdown: .eventLoopFuture { channel?.close() ?? .new() }
        )
        
        if schedule {
            lifecycle.registerScheduler()
        }
        
        lifecycle.registerWorkers(workers)
    }

    private func start() -> EventLoopFuture<Channel> {
        // Much of this is courtesy of [apple/swift-nio-examples](
        // https://github.com/apple/swift-nio-examples/tree/main/http2-server/Sources/http2-server)
        func childChannelInitializer(
            channel: Channel
        ) -> EventLoopFuture<Void> {
            channel.pipeline
                .configureHTTPServerPipeline(withErrorHandling: true)
                .flatMap { channel.pipeline.addHandler(HTTPHandler(router: Router.default)) }
        }

        let serverBootstrap = ServerBootstrap(group: Loop.group)
            // Specify backlog and enable SO_REUSEADDR for the server
            // itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )

            // Set the handlers that are applied to the accepted
            // `Channel`s
            .childChannelInitializer(childChannelInitializer(channel:))

            // Enable SO_REUSEADDR for the accepted `Channel`s
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
            .map { boundChannel in
                guard let channelLocalAddress = boundChannel.localAddress else {
                    fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
                }
                
                Log.info("[Server] listening on \(channelLocalAddress.prettyName)")
                return boundChannel
            }
    }
}

extension SocketAddress {
    var prettyName: String {
        switch self {
        case .unixDomainSocket:
            return pathname ?? ""
        case .v4:
            let address = ipAddress ?? ""
            let port = port ?? 0
            return "\(address):\(port)"
        case .v6:
            let address = ipAddress ?? ""
            let port = port ?? 0
            return "\(address):\(port)"
        }
    }
}

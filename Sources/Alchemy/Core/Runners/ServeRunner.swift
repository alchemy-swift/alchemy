import NIO

/// Runs a HTTP server, listening on a socket and routing incoming
/// requests to `Services.router`. `ServeRunner` is the default
/// `Runner` of an Alchemy application.
final class ServeRunner: Runner {
    /// The socket to bind to.
    private let socket: Socket
    
    /// A channel representing the connection to the socket of this
    /// server.
    private var channel: Channel?
    
    /// Create a new server that will bind to the given socket.
    ///
    /// - Parameter socket: The socket this server will bind to and
    ///   listen at.
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

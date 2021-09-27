import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2
import Lifecycle

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
final class RunServe: Command {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
    static var shutdownAfterRun: Bool = false
    static var logStartAndFinish: Bool = false
    
    /// The host to serve at. Defaults to `127.0.0.1`.
    @Option var host = "127.0.0.1"
    
    /// The port to serve at. Defaults to `3000`.
    @Option var port = 3000
    
    /// The unix socket to serve at. If this is provided, the host and
    /// port will be ignored.
    @Option var unixSocket: String?
    
    /// The number of Queue workers that should be kicked off in
    /// this process. Defaults to `0`.
    @Option var workers: Int = 0
    
    /// Should the scheduler run in process, scheduling any recurring
    /// work. Defaults to `false`.
    @Flag var schedule: Bool = false
    
    /// Should migrations be run before booting. Defaults to `false`.
    @Flag var migrate: Bool = false
    
    @IgnoreDecoding
    private var channel: Channel?
    
    // MARK: Command

    func run() throws {
        let lifecycle = ServiceLifecycle.default
        if migrate {
            lifecycle.register(
                label: "Migrate",
                start: .eventLoopFuture {
                    Loop.group.next().wrapAsync {
                        try await Database.default.migrate()
                    }
                },
                shutdown: .none
            )
        }
        
        registerToLifecycle()
        
        if schedule {
            lifecycle.registerScheduler()
        }
        
        if workers > 0 {
            lifecycle.registerWorkers(workers, on: .default)
        }
    }
    
    func start() async throws {
        func childChannelInitializer(_ channel: Channel) async throws {
            try await channel.pipeline.addAnyTLS()
            try await channel.addHTTP()
        }
        
        let serverBootstrap = ServerBootstrap(group: Loop.group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.eventLoop.wrapAsync { try await childChannelInitializer(channel) }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        let channel: Channel
        if let unixSocket = unixSocket {
            channel = try await serverBootstrap.bind(unixDomainSocketPath: unixSocket).get()
        } else {
            channel = try await serverBootstrap.bind(host: host, port: port).get()
        }
        
        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        
        self.channel = channel
        Log.info("[Server] listening on \(channelLocalAddress.prettyName)")
    }
    
    func shutdown() async throws {
        try await channel?.close()
    }
}

@propertyWrapper
private struct IgnoreDecoding<T>: Decodable {
    var wrappedValue: T?
    
    init(from decoder: Decoder) throws {
        wrappedValue = nil
    }
    
    init() {
        wrappedValue = nil
    }
}

extension SocketAddress {
    /// A human readable description for this socket.
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

extension ChannelPipeline {
    /// Configures this pipeline with any TLS config in the
    /// `ApplicationConfiguration`.
    fileprivate func addAnyTLS() async throws {
        let config = Container.resolve(ApplicationConfiguration.self)
        if var tls = config.tlsConfig {
            if config.httpVersions.contains(.http2) { tls.applicationProtocols.append("h2") }
            if config.httpVersions.contains(.http1_1) { tls.applicationProtocols.append("http/1.1") }
            let sslContext = try NIOSSLContext(configuration: tls)
            let sslHandler = NIOSSLServerHandler(context: sslContext)
            try await addHandler(sslHandler)
        }
    }
}

extension Channel {
    /// Configures this channel to handle whatever HTTP versions the
    /// server should be speaking over.
    fileprivate func addHTTP() async throws {
        let config = Container.resolve(ApplicationConfiguration.self)
        if config.httpVersions.contains(.http2) {
            try await configureHTTP2SecureUpgrade(
                h2ChannelConfigurator: { h2Channel in
                    h2Channel.configureHTTP2Pipeline(
                        mode: .server,
                        inboundStreamInitializer: { channel in
                            channel.pipeline
                                .addHandlers([
                                    HTTP2FramePayloadToHTTP1ServerCodec(),
                                    HTTPHandler(router: Router.default)
                                ])
                        })
                        .map { _ in }
                },
                http1ChannelConfigurator: { http1Channel in
                    http1Channel.pipeline
                        .configureHTTPServerPipeline(withErrorHandling: true)
                        .flatMap { self.pipeline.addHandler(HTTPHandler(router: Router.default)) }
                }
            ).get()
        } else {
            try await pipeline.configureHTTPServerPipeline(withErrorHandling: true).get()
            try await pipeline.addHandler(HTTPHandler(router: Router.default))
        }
    }
}

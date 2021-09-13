import ArgumentParser
import NIO
import NIOSSL
import NIOHTTP1
import NIOHTTP2

/// Command to serve on launched. This is a subcommand of `Launch`.
/// The app will route with the singleton `HTTPRouter`.
struct ServeCommand<A: Application>: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "serve")
    }
    
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
    
    /// The environment file to load. Defaults to `env`
    @Option(name: .shortAndLong) var env: String = "env"
    
    // MARK: ParseableCommand
    
    func run() throws {
        Env.defaultLocation = env
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
        
        if migrate {
            lifecycle.register(
                label: "Migrate",
                start: .eventLoopFuture {
                    Loop.group.next()
                        .flatSubmit(Database.default.migrate)
                },
                shutdown: .none
            )
        }
        
        lifecycle.register(
            label: "Serve",
            start: .eventLoopFuture { start().map { channel = $0 } },
            shutdown: .eventLoopFuture { channel?.close() ?? .new() }
        )
        
        if schedule {
            lifecycle.registerScheduler()
        }
        
        lifecycle.registerWorkers(workers, on: .default)
    }

    private func start() -> EventLoopFuture<Channel> {
        let serverBootstrap = ServerBootstrap(group: Loop.group)
            // Specify backlog and enable SO_REUSEADDR for the server
            // itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            .childChannelInitializer { channel in
                return channel.pipeline
                    .addAnyTLS()
                    .flatMap { channel.addHTTP() }
            }

            // Enable SO_REUSEADDR for the accepted `Channel`s
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
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
    func addAnyTLS() -> EventLoopFuture<Void> {
        let config = Container.resolve(ServerConfiguration.self)
        if let tls = config.tlsConfig {
            let sslContext = try! NIOSSLContext(configuration: tls)
            let sslHandler = NIOSSLServerHandler(context: sslContext)
            return addHandler(sslHandler)
        } else {
            return .new()
        }
    }
}

extension Channel {
    func addHTTP() -> EventLoopFuture<Void> {
        let config = Container.resolve(ServerConfiguration.self)
        if config.httpVersions.contains(.http2) {
            return configureHTTP2SecureUpgrade(
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
                        .voided()
                },
                http1ChannelConfigurator: { http1Channel in
                    http1Channel.pipeline
                        .configureHTTPServerPipeline(withErrorHandling: true)
                        .flatMap { self.pipeline.addHandler(HTTPHandler(router: Router.default)) }
                }
            )
        } else {
            return pipeline
                .configureHTTPServerPipeline(withErrorHandling: true)
                .flatMap { self.pipeline.addHandler(HTTPHandler(router: Router.default)) }
        }
    }
}

extension Application {
    public func useHTTPS(key: String, cert: String) throws {
        let config = Container.resolve(ServerConfiguration.self)
        config.tlsConfig = TLSConfiguration
            .makeServerConfiguration(
                certificateChain: try NIOSSLCertificate
                    .fromPEMFile(cert)
                    .map { NIOSSLCertificateSource.certificate($0) },
                privateKey: .file(key))
    }
    
    public func useHTTPS(tlsConfig: TLSConfiguration) {
        let config = Container.resolve(ServerConfiguration.self)
        config.tlsConfig = tlsConfig
    }
    
    public func useHTTP2(key: String, cert: String) throws {
        let config = Container.resolve(ServerConfiguration.self)
        config.httpVersions = [.http2, .http1_1]
        try useHTTPS(key: key, cert: cert)
    }
    
    public func useHTTP2(tlsConfig: TLSConfiguration) {
        let config = Container.resolve(ServerConfiguration.self)
        config.httpVersions = [.http2, .http1_1]
        useHTTPS(tlsConfig: tlsConfig)
    }
}

public final class ServerConfiguration {
    public var tlsConfig: TLSConfiguration?
    public var httpVersions: [HTTPVersion] = [.http1_1]
}

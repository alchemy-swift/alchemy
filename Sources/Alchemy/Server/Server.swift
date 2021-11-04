import NIO
import NIOSSL
import NIOHTTP2

final class Server {
    @Inject private var config: ServerConfiguration
    
    private var channel: Channel?
    
    func listen(on socket: Socket) async throws {
        func childChannelInitializer(_ channel: Channel) async throws {
            for upgrade in config.upgrades() {
                try await upgrade.upgrade(channel: channel)
            }
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
        switch socket {
        case .ip(let host, let port):
            channel = try await serverBootstrap.bind(host: host, port: port).get()
        case .unix(let path):
            channel = try await serverBootstrap.bind(unixDomainSocketPath: path).get()
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

extension ServerConfiguration {
    fileprivate func upgrades() -> [ServerUpgrade] {
        return [
            // TLS upgrade, if tls is configured
            tlsConfig.map { TLSUpgrade(config: $0) },
            // HTTP upgrader
            HTTPUpgrade(handler: HTTPHandler(handler: Router.default.handle), versions: httpVersions)
        ].compactMap { $0 }
    }
}

extension SocketAddress {
    /// A human readable description for this socket.
    fileprivate var prettyName: String {
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

import Hummingbird
import NIOCore

public enum BindAddress {
    case hostname(String, port: Int)
    case unixDomainSocket(path: String)
}

extension Application {
    public func addHTTPListener(address: BindAddress, logResponses: Bool) {
        let server = buildHummingbirdApplication(address: address, logResponses: logResponses)
        lifecycle.addService(server)
    }

    private func buildHummingbirdApplication(address: BindAddress, logResponses: Bool) -> Hummingbird.Application<Responder> {
        .init(
            responder: Responder(
                logResponses: logResponses
            ),
            server: server,
            configuration: ApplicationConfiguration(
                address: {
                    switch address {
                    case .hostname(let host, let port):
                        return .hostname(host, port: port)
                    case .unixDomainSocket(let path):
                        return .unixDomainSocket(path: path)
                    }
                }(),
                serverName: nil,
                backlog: 256,
                reuseAddress: true
            ),
            onServerRunning: { onServerStart(channel: $0, address: address) },
            eventLoopGroupProvider: .shared(LoopGroup),
            logger: Log
        )
    }

    private func onServerStart(channel: Channel, address: BindAddress) {
        switch address {
        case .hostname(let host, let port):
            let link = "[http://\(host):\(port)]".bold
            Log.info("Server running on \(link).")
        case .unixDomainSocket(let path):
            Log.info("Server running on \(path).")
        }

        if Env.isXcode {
            Log.comment("Press Cmd+Period to stop the server")
        } else {
            Log.comment("Press Ctrl+C to stop the server".yellow)
            print()
        }
    }
}

import NIO
import NIOSSL

struct TLSUpgrade: ServerUpgrade {
    let config: TLSConfiguration
    
    func upgrade(channel: Channel) async throws {
        let sslContext = try NIOSSLContext(configuration: config)
        let sslHandler = NIOSSLServerHandler(context: sslContext)
        try await channel.pipeline.addHandler(sslHandler)
    }
}

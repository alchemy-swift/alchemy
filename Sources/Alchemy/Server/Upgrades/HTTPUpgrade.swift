import NIO
import NIOHTTP2

struct HTTPUpgrade: ServerUpgrade {
    let handler: HTTPHandler
    let versions: [HTTPVersion]
    
    func upgrade(channel: Channel) async throws {
        guard versions.contains(.http2) else {
            try await upgradeHttp1(channel: channel).get()
            return
        }
        
        try await channel
            .configureHTTP2SecureUpgrade(
                h2ChannelConfigurator: upgradeHttp2,
                http1ChannelConfigurator: upgradeHttp1)
            .get()
    }
    
    private func upgradeHttp1(channel: Channel) -> EventLoopFuture<Void> {
        channel.pipeline
            .configureHTTPServerPipeline(withErrorHandling: true)
            .flatMap { channel.pipeline.addHandler(handler) }
    }
    
    private func upgradeHttp2(channel: Channel) -> EventLoopFuture<Void> {
        channel.configureHTTP2Pipeline(
            mode: .server,
            inboundStreamInitializer: {
                $0.pipeline.addHandlers([HTTP2FramePayloadToHTTP1ServerCodec(), handler])
            })
            .map { _ in }
    }
}

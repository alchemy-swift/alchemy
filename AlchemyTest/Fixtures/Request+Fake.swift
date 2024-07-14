@testable
import Alchemy

extension Request {
    public static func fake(
        method: HTTPRequest.Method = .GET,
        uri: String = "foo",
        headers: HTTPFields = [:],
        version: HTTPVersion = .http1_1,
        body: Bytes? = nil,
        localAddress: SocketAddress? = nil,
        remoteAddress: SocketAddress? = nil,
        eventLoop: EventLoop = EmbeddedEventLoop(),
        container: Container = Container()
    ) -> Request {
        Request(
            method: method,
            uri: uri,
            headers: headers, 
            version: version,
            body: body,
            localAddress: localAddress,
            remoteAddress: remoteAddress,
            eventLoop: eventLoop,
            container: container
        )
    }
}

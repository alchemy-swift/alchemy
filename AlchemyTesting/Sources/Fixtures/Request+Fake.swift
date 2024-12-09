@testable
import Alchemy
import NIOCore

extension Request {
    public static func fake(
        method: HTTPRequest.Method = .get,
        uri: String = "foo",
        headers: HTTPFields = [:],
        body: Bytes? = nil,
        localAddress: SocketAddress? = nil,
        remoteAddress: SocketAddress? = nil,
        container: Container = Container()
    ) -> Request {
        Request(
            method: method,
            uri: uri,
            headers: headers, 
            body: body,
            localAddress: localAddress,
            remoteAddress: remoteAddress,
            container: container
        )
    }
}

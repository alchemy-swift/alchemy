@testable
import Alchemy
import NIOCore

extension Request {
    /// Initialize a request fixture with the given data.
    public static func fixture(
        remoteAddress: SocketAddress? = nil,
        version: HTTPVersion = .http1_1,
        method: HTTPMethod = .GET,
        uri: String = "foo",
        headers: HTTPHeaders = [:],
        body: ByteContent? = nil
    ) -> Request {
        struct DummyContext: RequestContext {
            let eventLoop: EventLoop = EmbeddedEventLoop()
            let allocator: ByteBufferAllocator = .init()
            let remoteAddress: SocketAddress? = nil
        }
        
        let head = HTTPRequestHead(version: version, method: method, uri: uri, headers: headers)
        return Request(head: head, body: nil, context: DummyContext())
    }
}

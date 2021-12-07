@testable
import Alchemy
import Hummingbird
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
        struct DummyContext: HBRequestContext {
            let eventLoop: EventLoop = EmbeddedEventLoop()
            let allocator: ByteBufferAllocator = .init()
            let remoteAddress: SocketAddress? = nil
        }
        
        let dummyApp = HBApplication()
        let head = HTTPRequestHead(version: version, method: method, uri: uri, headers: headers)
        let req = HBRequest(head: head, body: .byteBuffer(body?.buffer), application: dummyApp, context: DummyContext())
        return Request(hbRequest: req)
    }
}

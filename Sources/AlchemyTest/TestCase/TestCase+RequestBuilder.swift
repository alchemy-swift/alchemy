@testable
import Alchemy
import NIOCore
import Hummingbird

extension TestCase: ClientProvider {
    public typealias Res = Response
    
    public var partialRequest: Client.Request { get { .init() } set {}}
    public var builder: TestRequestBuilder {
        TestRequestBuilder()
    }
}

public final class TestRequestBuilder: RequestBuilder {
    public typealias Res = Response
    public typealias Builder = TestRequestBuilder
    
    public var builder: TestRequestBuilder { self }
    public var partialRequest: Client.Request = .init()
    
    public func execute() async throws -> Response {
        let head = HTTPRequestHead(version: .http1_1, method: partialRequest.method, uri: partialRequest.urlComponents.path, headers: partialRequest.headers)
        let request = Request(head: head, bodyBuffer: partialRequest.body?.buffer, remoteAddress: nil)
        return await Router.default.handle(request: request)
    }
}

extension Request {
    /// Initialize a request with the given head, body, and remote address.
    public convenience init(head: HTTPRequestHead, bodyBuffer: ByteBuffer? = nil, remoteAddress: SocketAddress?) {
        let dummyApp = HBApplication()
        let context = DummyContext()
        let req = HBRequest(head: head, body: .byteBuffer(bodyBuffer), application: dummyApp, context: context)
        self.init(hbRequest: req)
    }
    
    public static func string(_ body: String, type: ContentType) -> Request {
        let dummyApp = HBApplication()
        let context = DummyContext()
        var headers = HTTPHeaders()
        headers.contentType = type
        let head = HTTPRequestHead(version: .http1_1, method: .GET, uri: "foo", headers: headers)
        let req = HBRequest(head: head, body: .byteBuffer(ByteBuffer(string: body)), application: dummyApp, context: context)
        return Request(hbRequest: req)
    }
}

struct DummyContext: HBRequestContext {
    let eventLoop: EventLoop = EmbeddedEventLoop()
    let allocator: ByteBufferAllocator = .init()
    let remoteAddress: SocketAddress? = nil
}

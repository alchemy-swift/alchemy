@testable
import Alchemy
import NIOCore
import Hummingbird

extension TestCase: RequestBuilder {
    public typealias Res = Response
    
    public var builder: TestRequestBuilder {
        TestRequestBuilder()
    }
}

public final class TestRequestBuilder: RequestBuilder {
    public var builder: TestRequestBuilder { self }
    
    private var queries: [String: String] = [:]
    private var headers: [String: String] = [:]
    private var createBody: (() throws -> ByteBuffer?)?

    public func withHeader(_ header: String, value: String) -> TestRequestBuilder {
        headers[header] = value
        return self
    }
    
    public func withQuery(_ query: String, value: String) -> TestRequestBuilder {
        queries[query] = value
        return self
    }
    
    public func withBody(_ createBody: @escaping () throws -> ByteBuffer?) -> TestRequestBuilder {
        self.createBody = createBody
        return self
    }
    
    public func request(_ method: HTTPMethod, _ path: String) async throws -> Response {
        await Router.default.handle(
            request: Request(
                head: .init(
                    version: .http1_1,
                    method: method,
                    uri: path + queryString(for: path),
                    headers: HTTPHeaders(headers.map { ($0, $1) })
                ),
                bodyBuffer: try createBody?(),
                remoteAddress: nil))
    }
    
    private func queryString(for path: String) -> String {
        guard queries.count > 0 else {
            return ""
        }
        
        let questionMark = path.contains("?") ? "&" : "?"
        return questionMark + queries.map { "\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")" }.joined(separator: "&")
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

@testable import Alchemy

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

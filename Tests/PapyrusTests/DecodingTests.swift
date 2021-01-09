import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    func testDecodeRequest() throws {
        let body = try JSONEncoder().encode(SomeJSON(string: "baz", int: 0))
        let mockRequest = MockRequest(
            headers: ["header1": "foo"],
            paths: ["path1": "bar"],
            queries: [
                "query1": 1,
                "query3": "three",
                "query6": true,
            ],
            bodyData: body
        )
        let decodedRequest = try DecodeTestRequest(from: mockRequest)
        XCTAssertEqual(decodedRequest.header1, "foo")
        XCTAssertEqual(decodedRequest.path1, "bar")
        XCTAssertEqual(decodedRequest.query1, 1)
        XCTAssertEqual(decodedRequest.query2, nil)
        XCTAssertEqual(decodedRequest.query3, "three")
        XCTAssertEqual(decodedRequest.query4, nil)
        XCTAssertEqual(decodedRequest.body.string, "baz")
        XCTAssertEqual(decodedRequest.body.int, 0)
    }
    
    /// Decoding `@Body` with content `urlEncoded` isn't supported yet.
    func testDecodeURLBodyThrows() throws {
        XCTAssertThrowsError(try TestURLBody(from: MockRequest()))
    }
}

struct MockRequest: DecodableRequest {
    let headers: [String: String]
    let paths: [String: String]
    let queries: [String: Any]
    let bodyData: Data?
    
    init(
        headers: [String: String] = [:],
        paths: [String: String] = [:],
        queries: [String: Any] = [:],
        bodyData: Data? = nil
    ) {
        self.headers = headers
        self.paths = paths
        self.queries = queries
        self.bodyData = bodyData
    }
    
    func header(for key: String) -> String? {
        self.headers[key]
    }
    
    func query(for key: String) -> String? {
        self.queries[key].map { "\($0)" }
    }
    
    func pathComponent(for key: String) -> String? {
        self.paths[key]
    }
    
    func decodeBody<T: Decodable>(encoding: BodyEncoding) throws -> T {
        try JSONDecoder().decode(T.self, from: self.bodyData ?? Data())
    }
}

struct DecodeTestRequest: EndpointRequest {
    @Path
    var path1: String
    
    @URLQuery
    var query1: Int
    
    @URLQuery
    var query2: Int?
    
    @URLQuery
    var query3: String?
    
    @URLQuery
    var query4: String?
    
    @URLQuery
    var query5: Bool?
    
    @URLQuery
    var query6: Bool
    
    @Header
    var header1: String
    
    @Body
    var body: SomeJSON
}

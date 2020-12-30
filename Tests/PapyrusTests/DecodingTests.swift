import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    func testDecodeRequest() throws {
        let decodedRequest = try TestRequest(from: MockRequest())
        XCTAssertEqual(decodedRequest.header1, "header1")
        XCTAssertEqual(decodedRequest.path1, "path1")
        XCTAssertEqual(decodedRequest.query1, 1)
        XCTAssertEqual(decodedRequest.query2, "query2")
        XCTAssertEqual(decodedRequest.query3, "query3")
        XCTAssertEqual(decodedRequest.query4, ["query2"])
        XCTAssertEqual(decodedRequest.query5, ["query5"])
        XCTAssertEqual(decodedRequest.body.string, "test")
        XCTAssertEqual(decodedRequest.body.int, 0)
    }
    
    func testDecodeURLBody() throws {
        let decodedRequest = try TestURLBody(from: MockRequest())
        XCTAssertEqual(decodedRequest.body.string, "test1")
        XCTAssertEqual(decodedRequest.body.int, 1)
    }
    
    func testDecodeMultipleBodyThrows() {
        XCTAssertThrowsError(try MultipleBodies(from: MockRequest()))
    }
}

struct MockRequest: DecodableRequest {
    let headers: [String: String]
    let paths: [String: String]
    let queries: [String: String]
    let bodyData: Data?
    
    init(
        headers: [String: String] = [:],
        paths: [String: String] = [:],
        queries: [String: String] = [:],
        bodyData: Data? = nil
    ) {
        self.headers = headers
        self.paths = paths
        self.queries = queries
        self.bodyData = bodyData
    }
    
    func getHeader(for key: String) throws -> String {
        self.headers[key] ?? ""
    }
    
    func getQuery(for key: String) throws -> String {
        self.queries[key] ?? ""
    }
    
    func getPathComponent(for key: String) throws -> String {
        self.paths[key] ?? ""
    }
    
    func getBody<T>() throws -> T where T : Decodable {
        try JSONDecoder().decode(T.self, from: self.bodyData ?? Data())
    }
}

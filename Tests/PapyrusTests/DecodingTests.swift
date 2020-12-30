import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    func testExample() throws {
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
}

struct MockRequest: DecodableRequest {
    func getHeader(for key: String) throws -> String {
        key
    }
    
    func getQuery(for key: String) throws -> String {
        key
    }
    
    func getPathComponent(for key: String) throws -> String {
        key
    }
    
    func getBody<T>() throws -> T where T : Decodable {
        let data = try JSONEncoder().encode(SomeJSON(string: "test", int: 0))
        return try JSONDecoder().decode(T.self, from: data)
    }
}

import XCTest
@testable import Papyrus

final class EncodingTests: XCTestCase {
    private let testAPI = TestAPI(baseURL: "http://localhost")
    
    func testBaseURL() {
        XCTAssertEqual(self.testAPI.post.baseURL, "http://localhost")
    }
    
    func testEncodePathQueryHeadersJSONBody() throws {
        let params = try self.testAPI.post.parameters(
            dto: TestRequest(
                path1: "one",
                query1: 0,
                query2: "two",
                query3: nil,
                query4: ["three", "six"],
                query5: [],
                query6: nil,
                query7: true,
                header1: "header_value",
                body: SomeJSON(string: "foo", int: 1)
            )
        )
        XCTAssertEqual(params.method, .post)
        XCTAssert(params.fullPath.hasPrefix("/foo/one/bar"))
        XCTAssertEqual(params.headers, ["header1": "header_value"])
        print("suffix: \(params.fullPath)")
        XCTAssert(
            params.fullPath.hasSuffix([
                "?query1=0",
                "&query2=two",
                "&query4%5B%5D=three",
                "&query4%5B%5D=six",
                "&query7=1",
            ].joined())
        )
        XCTAssertNotNil(params.body)
        XCTAssertEqual(params.bodyEncoding, .json)
        
        let bodyData = try JSONEncoder().encode(params.body)
        let expectedData = try JSONEncoder().encode(SomeJSON(string: "foo", int: 1))
        XCTAssertEqual(bodyData, expectedData)
    }
    
    func testEncodeURLBody() throws {
        let params = try self.testAPI.urlBody
            .parameters(dto: TestURLBody(body: SomeJSON(string: "test", int: 0)))
        XCTAssertEqual(params.method, .put)
        XCTAssert(params.fullPath.hasPrefix("/body"))
        XCTAssertEqual(params.bodyEncoding, .urlEncoded)
    }
    
    func testMultipleBodyThrows() throws {
        XCTAssertThrowsError(try self.testAPI.multipleBodies.parameters(dto: MultipleBodies()))
    }
}

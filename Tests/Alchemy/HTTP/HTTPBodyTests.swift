import AlchemyTest

final class HTTPBodyTests: XCTestCase {
    func testStringLiteral() throws {
        let body: HTTPBody = "foo"
        XCTAssertEqual(body.contentType, .plainText)
        XCTAssertEqual(body.decodeString(), "foo")
    }
}

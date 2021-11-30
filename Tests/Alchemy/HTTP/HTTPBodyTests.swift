import AlchemyTest

final class HTTPBodyTests: XCTestCase {
    func testStringLiteral() throws {
        let body: Content = "foo"
        XCTAssertEqual(body.contentType, .plainText)
        XCTAssertEqual(body.string(), "foo")
    }
}

import AlchemyTest

final class HTTPErrorTests: XCTestCase {
    func testConvertResponse() throws {
        try HTTPError(.badGateway, message: "foo")
            .response()
            .assertStatus(.badGateway)
            .assertJson(["message": "foo"])
    }
}

import AlchemyTest

final class HTTPErrorTests: XCTestCase {
    func testConvertResponse() throws {
        try HTTPError(.badGateway, message: "foo")
            .convert()
            .assertStatus(.badGateway)
            .assertJson(["message": "foo"])
    }
}

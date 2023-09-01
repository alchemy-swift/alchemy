import AlchemyTest

final class ValidationErrorTests: XCTestCase {
    func testConvertResponse() throws {
        try ValidationError("bar")
            .response()
            .assertStatus(.badRequest)
            .assertJson(["validation_error": "bar"])
    }
}

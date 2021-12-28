import AlchemyTest

final class ResponseConvertibleTests: XCTestCase {
    func testConvertArray() throws {
        let array = ["one", "two"]
        try array.response().assertOk().assertJson(array)
    }
}

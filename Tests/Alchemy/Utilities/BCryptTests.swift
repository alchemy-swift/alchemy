import AlchemyTest

final class BcryptTests: XCTestCase {
    func testBcrypt() throws {
        let hashed = try Bcrypt.hash("foo")
        XCTAssertTrue(try Bcrypt.verify("foo", created: hashed))
    }
    
    func testCostTooLow() {
        XCTAssertThrowsError(try Bcrypt.hash("foo", cost: 1))
    }
}

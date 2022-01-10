import AlchemyTest

final class BcryptTests: TestCase<TestApp> {
    func testBcrypt() async throws {
        let hashed = try await Bcrypt.hash("foo")
        let verify = try await Bcrypt.verify(plaintext: "foo", hashed: hashed)
        XCTAssertTrue(verify)
    }
    
    func testCostTooLow() {
        XCTAssertThrowsError(try Bcrypt.hashSync("foo", cost: 1))
    }
}

import AlchemyTest

final class BcryptTests: TestCase<TestApp> {
    func testBcrypt() async throws {
        let hashed = try await Bcrypt.hashAsync("foo")
        let verify = try await Bcrypt.verifyAsync(plaintext: "foo", hashed: hashed)
        XCTAssertTrue(verify)
    }
    
    func testCostTooLow() {
        XCTAssertThrowsError(try Bcrypt.hash("foo", cost: 1))
    }
}

import AlchemyTest

final class BcryptTests: TestCase<TestApp> {
    func testBcrypt() async throws {
        let hashed = try await Hash.hash("foo")
        let verify = try await Hash.verify(plaintext: "foo", hashed: hashed)
        XCTAssertTrue(verify)
    }
    
    func testCostTooLow() {
        XCTAssertThrowsError(try Hash.hashSync("foo", cost: 1))
    }
}

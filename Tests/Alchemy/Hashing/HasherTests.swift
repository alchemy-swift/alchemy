import AlchemyTest

final class HasherTests: TestCase<TestApp> {
    func testBcrypt() async throws {
        let hashed = try await Hash.makeAsync("foo")
        let verify = try await Hash.verifyAsync("foo", hash: hashed)
        XCTAssertTrue(verify)
    }
    
    func testBcryptCostTooLow() {
        XCTAssertThrowsError(try Hash(.bcrypt(rounds: 1)).make("foo"))
    }
    
    func testSHA256() throws {
        let hashed = try Hash(.sha256).make("foo")
        let verify = try Hash(.sha256).verify("foo", hash: hashed)
        XCTAssertTrue(verify)
    }
}

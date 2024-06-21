import AlchemyTest

final class HasherTests: TestCase<TestApp> {
    func testBcrypt() async throws {
        let hashed = try await Hash.make("foo")
        let verify = try await Hash.verify("foo", hash: hashed)
        XCTAssertTrue(verify)
    }
    
    func testBcryptCostTooLow() {
        XCTAssertThrowsError(try Hash(.bcrypt(rounds: 1)).makeSync("foo"))
    }
    
    func testSHA256() throws {
        let hashed = try Hash(.sha256).makeSync("foo")
        let verify = try Hash(.sha256).verifySync("foo", hash: hashed)
        XCTAssertTrue(verify)
    }
}

import AlchemyTesting

struct HasherTests {
    @Test func bcrypt() async throws {
        let hashed = try await Hash.make("foo")
        let verify = try await Hash.verify("foo", hash: hashed)
        #expect(verify)
    }
    
    @Test func sha256() throws {
        let hashed = Hash(.sha256).makeSync("foo")
        let verify = Hash(.sha256).verifySync("foo", hash: hashed)
        #expect(verify)
    }
}

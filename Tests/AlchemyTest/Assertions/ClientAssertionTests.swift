import AlchemyTest

final class ClientAssertionTests: TestCase<TestApp> {
    func testAssertNothingSent() {
        Http.assertNothingSent()
    }
    
    func testAssertSent() async throws {
        Http.stub()
        _ = try await Http.get("https://localhost:3000/foo?bar=baz")
        Http.assertSent(1) {
            $0.hasPath("/foo") &&
            $0.hasQuery("bar", value: "baz")
        }
        
        _ = try await Http.get("https://localhost:3000/bar")
        Http.assertSent(2) {
            $0.hasPath("/bar")
        }
    }
}

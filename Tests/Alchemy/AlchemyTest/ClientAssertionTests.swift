import AlchemyTest

final class ClientAssertionTests: TestCase<TestApp> {
    override func setUp() async throws {
        try await super.setUp()
        Http.stub()
    }

    func testAssertNothingSent() {
        Http.assertNothingSent()
    }
    
    func testAssertSent() async throws {
        _ = try await Http.get("https://localhost:3000/foo?bar=baz")
        Http.assertSent(1) {
            $0.hasMethod(.GET) &&
            $0.hasPath("/foo") &&
            $0.hasQuery("bar", value: "baz")
        }

        _ = try await Http
            .withJSON(User(name: "Cyanea", age: 35))
            .post("https://localhost:3000/bar")
        Http.assertSent(2) {
            $0.hasMethod(.POST) &&
            $0.hasPath("/bar") &&
            $0["name"] == "Cyanea" &&
            $0["age"] == 35
        }
    }
}

private struct User: Codable {
    let name: String
    let age: Int
}

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
        
        struct User: Codable {
            let name: String
            let age: Int
        }
        
        let user = User(name: "Cyanea", age: 35)
        _ = try await Http
            .withJSON(user)
            .post("https://localhost:3000/bar")
        
        Http.assertSent(2) {
            $0.hasMethod(.POST) &&
            $0.hasPath("/bar") &&
            $0["name"].string == "Cyanea" &&
            $0["age"].int == 35
        }
    }
}

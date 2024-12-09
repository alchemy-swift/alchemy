import AlchemyTesting

final class ClientAssertionTests {
    let client = Client().stub()

    var http: Client.Builder {
        client.builder()
    }

    deinit { try? client.shutdown() }

    @Test func assertNothingSent() {
        http.assertNothingSent()
    }
    
    @Test func assertSent() async throws {
        _ = try await http.get("https://localhost:3000/foo?bar=baz")
        http.assertSent(1) {
            $0.hasMethod(.get) &&
            $0.hasPath("/foo") &&
            $0.hasQuery("bar", value: "baz")
        }

        _ = try await http
            .withJSON(User(name: "Cyanea", age: 35))
            .post("https://localhost:3000/bar")
        http.assertSent(2) {
            $0.hasMethod(.post) &&
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

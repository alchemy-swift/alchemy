@testable
import Alchemy
import AlchemyTest

final class ClientTests: TestCase<TestApp> {
    func testQueries() async throws {
        Http.stub([
            ("localhost/foo", .stub(.unauthorized)),
            ("localhost/*", .stub(.ok)),
            ("*", .stub(.ok)),
        ])
        try await Http.withQueries(["foo":"bar"]).get("https://localhost/baz")
            .assertOk()
        
        try await Http.withQueries(["bar":"2"]).get("https://localhost/foo?baz=1")
            .assertUnauthorized()
        
        try await Http.get("https://example.com")
            .assertOk()
        
        Http.assertSent { $0.hasQuery("foo", value: "bar") }
        Http.assertSent { $0.hasQuery("bar", value: 2) && $0.hasQuery("baz", value: 1) }
    }
}

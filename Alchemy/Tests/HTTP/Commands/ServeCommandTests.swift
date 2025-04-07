@testable
import Alchemy
import AlchemyTesting

@Suite(.mockTestApp)
struct ServeCommandTests {
    @Test func serve() async throws {
        Main.get("/foo", use: { _ in "hello" })
        Main.background("--port", "3000")
        try await Http.get("http://127.0.0.1:3000/foo")
            .expectBody("hello")

        #expect(Q.workers == 0)
        #expect(!Schedule.isStarted)
    }

    @Test func serveWithSideEffects() async throws {
        Main.get("/foo", use: { _ in "hello" })
        Main.background("--workers", "2", "--schedule", "--migrate")
        try await Http.get("http://127.0.0.1:3000/foo")
            .expectBody("hello")

        #expect(Q.workers == 2)
        #expect(Schedule.isStarted)
    }
}

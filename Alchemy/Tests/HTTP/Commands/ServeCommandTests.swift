@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct ServeCommandTests: TestSuite {
    @Test func serve() async throws {
        App.get("/foo", use: { _ in "hello" })
        App.background("--port", "3000")
        try await Http.get("http://127.0.0.1:3000/foo")
            .assertBody("hello")

        #expect(Q.workers == 0)
        #expect(!Schedule.isStarted)
    }

    @Test func serveWithSideEffects() async throws {
        App.get("/foo", use: { _ in "hello" })
        App.background("--workers", "2", "--schedule", "--migrate")
        try await Http.get("http://127.0.0.1:3000/foo")
            .assertBody("hello")

        #expect(Q.workers == 2)
        #expect(Schedule.isStarted)
    }
}

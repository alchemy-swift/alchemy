@testable
import Alchemy
import AlchemyTesting

struct ServeCommandTests: AppSuite {
    let app = TestApp()

    @Test func serve() async throws {
        try await withApp { app in
            app.get("/foo", use: { _ in "hello" })
            app.background("--port", "3000")
            try await Http.get("http://127.0.0.1:3000/foo")
                .assertBody("hello")

            #expect(Q.workers == 0)
            #expect(!Schedule.isStarted)
        }
    }
    
    @Test func serveWithSideEffects() async throws {
        try await withApp { app in
            app.get("/foo", use: { _ in "hello" })
            app.background("--workers", "2", "--schedule", "--migrate")
            try await Http.get("http://127.0.0.1:3000/foo")
                .assertBody("hello")

            #expect(Q.workers == 2)
            #expect(Schedule.isStarted)
        }
    }
}

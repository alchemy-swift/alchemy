@testable
import Alchemy
import AlchemyTest

final class ServeCommandTests: TestCase<TestApp> {
    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake()
        Queue.fake()
    }
    
    func testServe() async throws {
        app.get("/foo", use: { _ in "hello" })
        Task { try await app.run("--port", "3000") }
        try await Http.get("http://127.0.0.1:3000/foo")
            .assertBody("hello")
        
        XCTAssertEqual(Q.workers.count, 0)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testServeWithSideEffects() async throws {
        app.get("/foo", use: { _ in "hello" })
        Task { try await app.run("--workers", "2", "--schedule", "--migrate") }
        try await Http.get("http://127.0.0.1:3000/foo")
            .assertBody("hello")
        
        XCTAssertEqual(Q.workers.count, 2)
        XCTAssertTrue(Schedule.isStarted)
    }
}

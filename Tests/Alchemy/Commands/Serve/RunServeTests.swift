@testable
import Alchemy
import AlchemyTest

final class RunServeTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Database.fake()
        Queue.fake()
    }
    
    func testServe() async throws {
        app.get("/foo", use: { _ in "hello" })
        try RunServe(host: "127.0.0.1", port: 1234).run()
        app.lifecycle.start { _ in }
        
        try await Http.get("http://127.0.0.1:1234/foo")
            .assertBody("hello")
        
        XCTAssertEqual(Queue.default.workers.count, 0)
        XCTAssertFalse(Scheduler.default.isStarted)
        XCTAssertFalse(Database.default.didRunMigrations)
    }
    
    func testServeWithSideEffects() async throws {
        app.get("/foo", use: { _ in "hello" })
        try RunServe(host: "127.0.0.1", port: 1234, workers: 2, schedule: true, migrate: true).run()
        app.lifecycle.start { _ in }
        
        try await Http.get("http://127.0.0.1:1234/foo")
            .assertBody("hello")
        
        XCTAssertEqual(Queue.default.workers.count, 2)
        XCTAssertTrue(Scheduler.default.isStarted)
        XCTAssertTrue(Database.default.didRunMigrations)
    }
}

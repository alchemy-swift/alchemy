@testable
import Alchemy
import AlchemyTest

final class WorkCommandTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Queue.fake()
    }
    
    func testRun() throws {
        try WorkCommand(name: nil, workers: 5, schedule: false).run()
        XCTAssertEqual(Q.workers.count, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunName() throws {
        Queue.fake("a")
        try WorkCommand(name: "a", workers: 5, schedule: false).run()
        XCTAssertEqual(Q.workers.count, 0)
        XCTAssertEqual(Q("a").workers.count, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunCLI() async throws {
        try await app.start("queue:work", "--workers", "3", "--schedule", waitOrShutdown: false)
        XCTAssertEqual(Q.workers.count, 3)
        XCTAssertTrue(Schedule.isStarted)
    }
}

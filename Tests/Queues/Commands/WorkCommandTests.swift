@testable
import Alchemy
import AlchemyTest

final class WorkCommandTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Queue.fake()
    }
    
    func testRun() async throws {
        Task { try await WorkCommand.parse(["--workers", "5"]).run() }

        // hack to wait for the queue to boot up - should find a way to hook
        // into the command finishing.
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(Q.workers.count, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunName() async throws {
        Queue.fake("a")
        Task { try await WorkCommand.parse(["--name", "a", "--workers", "5"]).run() }

        // hack to wait for the queue to boot up - should find a way to hook
        // into the command finishing.
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(Q.workers.count, 0)
        XCTAssertEqual(Q("a").workers.count, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunCLI() async throws {
        Task { try await app.run("queue:work", "--workers", "3", "--schedule") }

        // hack to wait for the queue to boot up - should find a way to hook
        // into the command finishing.
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(Q.workers.count, 3)
        XCTAssertTrue(Schedule.isStarted)
    }
}

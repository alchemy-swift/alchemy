@testable
import Alchemy
import AlchemyTest

final class WorkCommandTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Queue.fake()
    }
    
    func testRun() async throws {
        app.background("queue:work", "--workers", "5")

        // wait for services to boot up
        try await Task.sleep(for: .milliseconds(10))

        XCTAssertEqual(Q.workers, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunName() async throws {
        Queue.fake("a")
        app.background("queue:work", "--name", "a", "--workers", "5")

        // wait for services to boot up
        try await Task.sleep(for: .milliseconds(10))

        XCTAssertEqual(Q.workers, 0)
        XCTAssertEqual(Q("a").workers, 5)
        XCTAssertFalse(Schedule.isStarted)
    }
    
    func testRunCLI() async throws {
        app.background("queue:work", "--workers", "3", "--schedule")

        // wait for services to boot up
        try await Task.sleep(for: .milliseconds(10))

        XCTAssertEqual(Q.workers, 3)
        XCTAssertTrue(Schedule.isStarted)
    }
}

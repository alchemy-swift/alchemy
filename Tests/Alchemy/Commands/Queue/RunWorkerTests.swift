@testable
import Alchemy
import AlchemyTest

final class RunWorkerTests: TestCase<TestApp> {
    override func setUp() {
        super.setUp()
        Queue.fake()
    }
    
    func testRun() throws {
        let exp = expectation(description: "")
        
        try RunWorker(name: nil, workers: 5, schedule: false).run()
        app.lifecycle.start { _ in
            XCTAssertEqual(Q.workers.count, 5)
            XCTAssertFalse(self.app.scheduler.isStarted)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testRunName() throws {
        let exp = expectation(description: "")
        Queue.fake("a")
        try RunWorker(name: "a", workers: 5, schedule: false).run()
        
        app.lifecycle.start { _ in
            XCTAssertEqual(Q.workers.count, 0)
            XCTAssertEqual(Q("a").workers.count, 5)
            XCTAssertFalse(self.app.scheduler.isStarted)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testRunCLI() async throws {
        try app.start("worker", "--workers", "3", "--schedule")
        XCTAssertEqual(Q.workers.count, 3)
        XCTAssertTrue(app.scheduler.isStarted)
    }
}

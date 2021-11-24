@testable
import Alchemy
import AlchemyTest

final class RunWorkerTests: TestCase<TestApp> {
    func testRun() throws {
        let exp = expectation(description: "")
        
        Queue.fake()
        try RunWorker(name: nil, workers: 5, schedule: false).run()
        app.lifecycle.start { _ in
            XCTAssertEqual(Queue.default.workers.count, 5)
            XCTAssertFalse(Scheduler.default.isStarted)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testRunName() throws {
        let exp = expectation(description: "")
        
        Queue.fake()
        Queue.fake("a")
        try RunWorker(name: "a", workers: 5, schedule: false).run()
        
        app.lifecycle.start { _ in
            XCTAssertEqual(Queue.default.workers.count, 0)
            XCTAssertEqual(Queue.resolve("a").workers.count, 5)
            XCTAssertFalse(Scheduler.default.isStarted)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testRunCLI() async throws {
        let exp = expectation(description: "")
        
        Queue.fake()
        app.start("worker", "--workers", "3", "--schedule") { _ in
            XCTAssertEqual(Queue.default.workers.count, 3)
            XCTAssertTrue(Scheduler.default.isStarted)
            exp.fulfill()
        }
        
        await waitForExpectations(timeout: kMinTimeout)
    }
}

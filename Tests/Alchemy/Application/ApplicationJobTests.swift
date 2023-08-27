@testable
import Alchemy
import AlchemyTest

final class ApplicationJobTests: TestCase<TestApp> {
    override func tearDown() {
        super.tearDown()
        JobRegistry.reset()
    }
    
    func testRegisterJob() {
        app.registerJob(TestJob.self)
        XCTAssertTrue(app.registeredJobs.contains(where: {
            id(of: $0) == id(of: TestJob.self)
        }))
    }
}

private struct TestJob: Job {
    func run() async throws {}
}

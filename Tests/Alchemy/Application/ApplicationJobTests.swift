import AlchemyTest

final class ApplicationJobTests: TestCase<TestApp> {
    func testRegisterJob() {
        app.registerJob(TestJob.self)
        XCTAssertTrue(app.registeredJobs.contains(where: {
            id(of: $0) == id(of: TestJob.self)
        }))
    }
}

struct TestJob: Job {
    func run() async throws {}
}

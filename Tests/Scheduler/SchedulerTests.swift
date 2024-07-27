@testable
import Alchemy
import AlchemyTest
import NIOEmbedded

final class SchedulerTests: TestCase<TestApp> {
    private var queue = Queue.fake()

    override func setUp() {
        super.setUp()
        self.queue = Queue.fake()
    }
    
    func testScheduleTask() {
        makeSchedule().everySecond()
        app.background("schedule")
        waitForExpectations(timeout: 2)
    }
    
    func testScheduleJob() async throws {
        Schedule.job(TestJob()).everySecond()
        app.background("schedule")
        try await Task.sleep(for: .seconds(1))
        await queue.assertPushed(TestJob.self)
    }
    
    func testDoesntRunNoNext() {
        makeSchedule(invertExpect: true).cron("0 0 0 11 9 * 1993")
        app.background("schedule")
        waitForExpectations(timeout: 2)
    }
    
    private func makeSchedule(invertExpect: Bool = false) -> Frequency {
        let exp = expectation(description: "")
        exp.isInverted = invertExpect
        var didRun = false
        return Schedule.task {
            // Don't let the schedule fullfill this expectation twice.
            guard !didRun else { return }
            didRun = true
            exp.fulfill()
        }
    }
}

private struct TestJob: Job, Codable, Equatable {
    func handle(context: JobContext) async throws {
        //
    }
}

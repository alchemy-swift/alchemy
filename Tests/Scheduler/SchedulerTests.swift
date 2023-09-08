@testable
import Alchemy
import AlchemyTest

final class SchedulerTests: TestCase<TestApp> {
    private var scheduler = Scheduler()
    private var loop = EmbeddedEventLoop()
    private var queue = Queue.fake()

    override func setUp() {
        super.setUp()
        self.scheduler = Scheduler()
        self.loop = EmbeddedEventLoop()
        self.queue = Queue.fake()
    }
    
    func testScheduleTask() {
        makeSchedule().everyDay()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: 0.1)
    }
    
    func testScheduleJob() async throws {
        scheduler.job(TestJob()).everyDay()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        try await Task.sleep(nanoseconds: 1 * 1_000_000)
        await queue.assertPushed(TestJob.self)
    }
    
    func testNoRunWithoutStart() {
        makeSchedule(invertExpect: true).everyDay()
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testStart() {
        makeSchedule().everyDay()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testStartTwiceRunsOnce() {
        makeSchedule().everyDay()
        scheduler.start(on: loop)
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testDoesntRunNoNext() {
        makeSchedule(invertExpect: true).cron("0 0 0 11 9 * 1993")
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: kMinTimeout)
    }
    
    private func makeSchedule(invertExpect: Bool = false) -> Frequency {
        let exp = expectation(description: "")
        exp.isInverted = invertExpect
        var didRun = false
        return scheduler.task {
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

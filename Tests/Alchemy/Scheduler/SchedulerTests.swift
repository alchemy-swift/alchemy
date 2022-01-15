@testable
import Alchemy
import AlchemyTest

final class SchedulerTests: TestCase<TestApp> {
    private var scheduler = Scheduler(isTesting: true)
    private var loop = EmbeddedEventLoop()
    
    override func setUp() {
        super.setUp()
        self.scheduler = Scheduler(isTesting: true)
        self.loop = EmbeddedEventLoop()
    }
    
    func testScheduleTask() {
        let exp = expectation(description: "")
        scheduler.run { exp.fulfill() }.daily()
        
        let loop = EmbeddedEventLoop()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testScheduleJob() {
        struct ScheduledJob: Job, Equatable {
            func run() async throws {}
        }
        
        let queue = Queue.fake()
        let loop = EmbeddedEventLoop()
        
        scheduler.job(ScheduledJob()).daily()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        
        let exp = expectation(description: "")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            queue.assertPushed(ScheduledJob.self)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
    }
    
    func testNoRunWithoutStart() {
        makeSchedule(invertExpect: true).daily()
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testStart() {
        makeSchedule().daily()
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testStartTwiceRunsOnce() {
        makeSchedule().daily()
        scheduler.start(on: loop)
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        waitForExpectations(timeout: kMinTimeout)
    }
    
    func testDoesntRunNoNext() {
        makeSchedule(invertExpect: true).expression("0 0 0 11 9 * 1993")
        scheduler.start(on: loop)
        loop.advanceTime(by: .hours(24))
        
        waitForExpectations(timeout: kMinTimeout)
    }
    
    private func makeSchedule(invertExpect: Bool = false) -> Schedule {
        let exp = expectation(description: "")
        exp.isInverted = invertExpect
        return Schedule {
            self.scheduler.addWork(schedule: $0) {
                exp.fulfill()
            }
        }
    }
}

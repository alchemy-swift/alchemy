@testable import Alchemy
import XCTest

final class SchedulerTests: XCTestCase {
    private var scheduler = Scheduler(isTesting: true)
    private var loop = EmbeddedEventLoop()
    
    override func setUp() {
        super.setUp()
        self.scheduler = Scheduler(isTesting: true)
        self.loop = EmbeddedEventLoop()
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
            self.scheduler.addWork(schedule: $0, work: exp.fulfill)
        }
    }
}

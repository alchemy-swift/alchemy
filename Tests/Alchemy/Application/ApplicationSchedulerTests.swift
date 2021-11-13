@testable
import Alchemy
import AlchemyTest

final class ApplicationSchedulerTests: TestCase<TestApp> {
    func testScheduleTask() {
        Scheduler.register(Scheduler(isTesting: true))
        let exp = expectation(description: "")
        Scheduler.default.run { exp.fulfill() }.daily()
        
        let loop = EmbeddedEventLoop()
        Scheduler.default.start(on: loop)
        loop.advanceTime(by: .hours(24))
        
        waitForExpectations(timeout: kMinTimeout)
    }
}

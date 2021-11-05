@testable
import Alchemy
import AlchemyTest

final class ApplicationSchedulerTests: TestCase<TestApp> {
    func testScheduleTask() {
        Scheduler(isTesting: true).makeDefault()
        let exp = expectation(description: "")
        app.schedule { exp.fulfill() }.daily()
        
        let loop = EmbeddedEventLoop()
        Scheduler.default.start(on: loop)
        loop.advanceTime(by: .hours(24))
        
        waitForExpectations(timeout: kMinTimeout)
    }
}

@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct SchedulerTests: TestSuite {
    let queue = Q.fake()

    @Test func scheduleTask() async throws {
        try await confirmation { confirm in
            Schedule.task { confirm() }.everySecond()
            App.background("schedule")
            try await Task.sleep(for: .seconds(1.01))
        }
    }
    
    @Test func scheduleJob() async throws {
        Schedule.job(TestJob()).everySecond()
        App.background("schedule")
        try await Task.sleep(for: .seconds(1.01))
        await queue.assertPushed(TestJob.self)
    }
    
    @Test func doesntRunNoNext() async throws {
        var didRun = false
        Schedule.task { didRun = true }.cron("0 0 0 11 9 * 1993")
        App.background("schedule")
        try await Task.sleep(for: .seconds(1.01))
        #expect(!didRun)
    }
}

private struct TestJob: Job, Codable, Equatable {
    func handle(context: JobContext) async throws {
        //
    }
}

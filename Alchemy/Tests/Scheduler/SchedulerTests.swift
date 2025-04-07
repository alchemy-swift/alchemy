@testable
import Alchemy
import AlchemyTesting

@Suite(.mockTestApp)
struct SchedulerTests {
    let queue = Q.fake()

    @Test func scheduleTask() async throws {
        try await confirmation { confirm in
            Schedule.task { confirm() }.everySecond()
            Main.background("schedule")
            try await Task.sleep(for: .seconds(1.01))
        }
    }
    
    @Test func scheduleJob() async throws {
        Schedule.job(TestJob()).everySecond()
        Main.background("schedule")
        try await Task.sleep(for: .seconds(1.01))
        await queue.expectPushed(TestJob.self)
    }
    
    @Test func doesntRunNoNext() async throws {
        var didRun = false
        Schedule.task { didRun = true }.cron("0 0 0 11 9 * 1993")
        Main.background("schedule")
        try await Task.sleep(for: .seconds(1.01))
        #expect(!didRun)
    }
}

private struct TestJob: Job, Codable, Equatable {
    func handle(context: JobContext) async throws {
        //
    }
}

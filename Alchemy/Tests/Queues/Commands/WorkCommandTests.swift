@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct WorkCommandTests: TestSuite {
    @Test func run() async throws {
        App.background("queue:work", "--workers", "5")

        // wait for worker to boot up
        try await Task.sleep(for: .milliseconds(10))

        #expect(Q.workers == 5)
        #expect(!Schedule.isStarted)
    }

    @Test func runSchedule() async throws {
        App.background("queue:work", "--workers", "3", "--schedule")

        // wait for worker to boot up
        try await Task.sleep(for: .milliseconds(10))

        #expect(Q.workers == 3)
        #expect(Schedule.isStarted)
    }

    @Test(.disabled("need to enable string -> service id"))
    func runName() async throws {}
}

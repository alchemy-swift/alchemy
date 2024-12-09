@testable
import Alchemy
import AlchemyTesting

struct JobRegistryTests {
    @Test func register() async throws {
        let registry = JobRegistry()
        let data = JobData.fixture(name: TestJob.name)
        await #expect(throws: Error.self) { try await registry.createJob(from: data) }
        registry.register(TestJob.self)
        #expect(try await registry.createJob(from: data).recoveryStrategy == .none)
    }
}

private struct TestJob: Job, Codable {
    func handle(context: JobContext) async throws {
        //
    }
}

private extension JobData {
    static func fixture(name: String) -> JobData {
        JobData(
            payload: "{}".data(using: .utf8)!,
            jobName: name,
            channel: "",
            attempts: 0,
            recoveryStrategy: .none,
            backoff: .seconds(0)
        )
    }
}

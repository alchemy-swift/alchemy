@testable
import Alchemy
import AlchemyTest

final class ApplicationJobTests: TestCase<TestApp> {
    func testRegisterJob() async throws {
        let data = JobData(payload: "{}".data(using: .utf8)!, jobName: "TestJob", channel: "", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        app.registerJob(TestJob.self)
        do {
            _ = try await JobRegistry.createJob(from: data)
        } catch {
            XCTFail()
        }
    }
}

private struct TestJob: Job, Codable {
    func handle(context: JobContext) async throws {
        //
    }
}

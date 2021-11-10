import AlchemyTest

final class DatabaseQueueTests: TestCase<TestApp> {
    var queue: Queue {
        Queue.default
    }
    
    override func setUp() {
        super.setUp()
        Database.fake(migrations: [Queue.AddJobsMigration()])
        Queue.config(default: .database(.default))
    }
    
    func testEnqueue() async throws {
        do {
            try await TestJob().dispatch()
        } catch {
            print("error: \(error)")
        }
    }
}

private struct TestJob: Job {
    func run() async throws {
        
    }
}

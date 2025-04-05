@testable
import Alchemy
import AlchemyTesting

struct QueueTests: AppSuite {
    let app = TestApp()

    private var allTests: [(StaticString, UInt) async throws -> Void] {
        [
            _testEnqueue,
            _testWorker,
            _testFailure,
            _testRetry,
        ]
    }

    @Test func jobDecoding() async {
        let fakeData = JobData(payload: Data(), jobName: "", channel: "", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await #expect(throws: Error.self) { try await Jobs.createJob(from: fakeData) }
        Jobs.register(RetryJob.self)
        let invalidData = JobData(payload: Data(), jobName: "RetryJob", channel: "foo", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await #expect(throws: Error.self) { try await Jobs.createJob(from: invalidData) }
    }
    
    @Test func databaseQueue() async throws {
        for test in allTests {
            try await withApp { _ in
                try await DB.fake(migrations: [Queue.AddJobsMigration()])
                Container.main.set(Queue.database)
                try await test(#filePath, #line)
            }
        }
    }
    
    @Test func memoryQueue() async throws {
        for test in allTests {
            try await withApp { _ in
                Q.fake()
                try await test(#filePath, #line)
            }
        }
    }
    
    @Test func redisQueue() async throws {
        for test in allTests {
            try await withApp { _ in
                Container.main.set(RedisClient.integration)
                Container.main.set(Queue.redis)

                guard await Redis.checkAvailable() else {
                    return
                }

                try await test(#filePath, #line)
                _ = try await Redis.send(command: "FLUSHDB").get()
            }
        }
    }
    
    private func _testEnqueue(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await RetryJob(foo: "bar").dispatch()
        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            XCTFail("Failed to dequeue a job.", file: file, line: line)
            return
        }
        
        XCTAssertEqual(jobData.jobName, "RetryJob", file: file, line: line)
        XCTAssertEqual(jobData.recoveryStrategy, .retry(3), file: file, line: line)
        XCTAssertEqual(jobData.backoff, .seconds(0), file: file, line: line)
        
        let decodedJob = try await Jobs.createJob(from: jobData)
        guard let retryJob = decodedJob as? RetryJob else {
            XCTFail("Failed to decode RetryJob \(jobData.jobName) \(type(of: decodedJob))", file: file, line: line)
            return
        }
        
        XCTAssertEqual(retryJob.foo, "bar", file: file, line: line)
    }
    
    private func _testWorker(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await confirmation { confirm in
            ConfirmableJob.didRun = {
                confirm()
            }

            try await ConfirmableJob().dispatch()
            app.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }
    }
    
    private func _testFailure(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await confirmation { confirm in
            FailureJob.didFinish = { confirm() }
            try await FailureJob().dispatch()
            app.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }

        #expect(try await Q.dequeue(from: ["default"]) == nil)
    }

    private func _testRetry(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await confirmation { confirm in
            RetryJob.didFail = { confirm() }
            try await RetryJob(foo: "bar").dispatch()
            app.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }

        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            Issue.record("Failed to dequeue a job.")
            return
        }

        #expect(jobData.jobName == "RetryJob")
        #expect(jobData.attempts == 1)
    }
}

private struct FailureJob: Job, Codable {
    static var didFinish: (() -> Void)? = nil
    
    func handle(context: JobContext) async throws {
        throw JobError("foo")
    }
    
    func finished(result: Result<Void, Error>) {
        FailureJob.didFinish?()
    }
}

private struct ConfirmableJob: Job, Codable {
    static var didRun: (() -> Void)? = nil
    
    func handle(context: JobContext) async throws {
        ConfirmableJob.didRun?()
    }
}

private struct RetryJob: Job, Codable {
    static var didFail: (() -> Void)? = nil
    
    let foo: String
    var recoveryStrategy: RecoveryStrategy = .retry(3)
    var retryBackoff: Duration = .seconds(0)

    func handle(context: JobContext) async throws {
        throw JobError(foo)
    }
    
    func failed(error: Error) {
        RetryJob.didFail?()
    }
}

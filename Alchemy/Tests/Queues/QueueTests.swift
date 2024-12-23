@testable
import Alchemy
import AlchemyTesting

final class QueueTests: TestCase<TestApp> {
    private lazy var allTests = [
        _testEnqueue,
        _testWorker,
        _testFailure,
        _testRetry,
    ]

    func testJobDecoding() async {
        let fakeData = JobData(payload: Data(), jobName: "", channel: "", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await AssertThrowsError(try await Jobs.createJob(from: fakeData))
        Jobs.register(RetryJob.self)
        let invalidData = JobData(payload: Data(), jobName: "RetryJob", channel: "foo", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await AssertThrowsError(try await Jobs.createJob(from: invalidData))
    }
    
    func testDatabaseQueue() async throws {
        for test in allTests {
            try await DB.fake(migrations: [Queue.AddJobsMigration()])
            Container.main.set(Queue.database)
            try await test(#filePath, #line)
        }
    }
    
    func testMemoryQueue() async throws {
        for test in allTests {
            Q.fake()
            try await test(#filePath, #line)
        }
    }
    
    func testRedisQueue() async throws {
        Container.main.set(RedisClient.integration)
        Container.main.set(Queue.redis)

        guard await Redis.checkAvailable() else {
            throw XCTSkip()
        }

        for test in allTests {
            try await test(#filePath, #line)
            _ = try await Redis.send(command: "FLUSHDB").get()
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
        let exp = expectation(description: "")
        ConfirmableJob.didRun = { exp.fulfill() }
        try await ConfirmableJob().dispatch()
        app.background("queue:work")
        await fulfillment(of: [exp], timeout: 2)
    }
    
    private func _testFailure(file: StaticString = #filePath, line: UInt = #line) async throws {
        let exp = expectation(description: "")
        FailureJob.didFinish = { exp.fulfill() }
        try await FailureJob().dispatch()

        app.background("queue:work")

        await fulfillment(of: [exp], timeout: 2)
        AssertNil(try await Q.dequeue(from: ["default"]))
    }

    /// This is a poorly written test - the worker may immediately retry the job
    /// leading to the exp being called twice.
    ///
    /// Could update the backoff, but then it won't be dequeuable for that long.
    private func _testRetry(file: StaticString = #filePath, line: UInt = #line) async throws {
        let exp = expectation(description: "")
        RetryJob.didFail = { exp.fulfill() }
        try await RetryJob(foo: "bar").dispatch()

        app.background("queue:work")
        await fulfillment(of: [exp], timeout: 1.1)

        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            XCTFail("Failed to dequeue a job.", file: file, line: line)
            return
        }

        XCTAssertEqual(jobData.jobName, "RetryJob", file: file, line: line)
        XCTAssertEqual(jobData.attempts, 1, file: file, line: line)
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

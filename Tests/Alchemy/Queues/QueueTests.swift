@testable
import Alchemy
import AlchemyTest

final class QueueTests: TestCase<TestApp> {
    private lazy var allTests = [
        _testEnqueue,
        _testWorker,
        _testFailure,
        _testRetry,
    ]

    func testPlugin() {
        let plugin = Queues(default: 1, queues: [1: .memory, 2: .memory], jobs: [RetryJob.self])
        plugin.registerServices(in: app)
        XCTAssertNotNil(Container.resolve(Queue.self))
        XCTAssertNotNil(Container.resolve(Queue.self, id: 1))
        XCTAssertNotNil(Container.resolve(Queue.self, id: 2))
        XCTAssertNotNil(Jobs.creators[RetryJob.name])
    }
    
    func testJobDecoding() async {
        let fakeData = JobData(payload: Data(), jobName: "", channel: "", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await AssertThrowsError(try await Jobs.createJob(from: fakeData))
        Jobs.register(RetryJob.self)
        let invalidData = JobData(payload: Data(), jobName: "RetryJob", channel: "foo", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await AssertThrowsError(try await Jobs.createJob(from: invalidData))
    }
    
    func testDatabaseQueue() async throws {
        for test in allTests {
            try await Database.fake(migrations: [Queue.AddJobsMigration()])
            Container.register(Queue.database)
            try await test(#filePath, #line)
        }
    }
    
    func testMemoryQueue() async throws {
        for test in allTests {
            Queue.fake()
            try await test(#filePath, #line)
        }
    }
    
    func testRedisQueue() async throws {
        let client = RedisClient.testing
        Container.register(client).singleton()
        Container.register(Queue.redis).singleton()
        app.lifecycle.registerShutdown(label: "Redis", .async(client.shutdown))

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
        ConfirmableJob.didRun = exp.fulfill
        try await ConfirmableJob().dispatch()

        let loop = EmbeddedEventLoop()
        Q.startWorker(on: loop)
        loop.advanceTime(by: .seconds(5))

        await fulfillment(of: [exp], timeout: kMinTimeout)
    }
    
    private func _testFailure(file: StaticString = #filePath, line: UInt = #line) async throws {
        let exp = expectation(description: "")
        FailureJob.didFinish = exp.fulfill
        try await FailureJob().dispatch()

        let loop = EmbeddedEventLoop()
        Q.startWorker(on: loop)
        loop.advanceTime(by: .seconds(5))
        
        await fulfillment(of: [exp], timeout: kMinTimeout)
        AssertNil(try await Q.dequeue(from: ["default"]))
    }
    
    private func _testRetry(file: StaticString = #filePath, line: UInt = #line) async throws {
        let exp = expectation(description: "")
        RetryJob.didFail = exp.fulfill
        try await RetryJob(foo: "bar").dispatch()

        let loop = EmbeddedEventLoop()
        Q.startWorker(untilEmpty: false, on: loop)
        loop.advanceTime(by: .seconds(5))
        await fulfillment(of: [exp], timeout: kMinTimeout)

        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            XCTFail("Failed to dequeue a job.", file: file, line: line)
            return
        }

        XCTAssertEqual(jobData.jobName, "RetryJob", file: file, line: line)
        XCTAssertEqual(jobData.attempts, 1, file: file, line: line)
    }

#if os(Linux)
    /// Wait on an array of expectations for up to the specified timeout, and optionally specify whether they
    /// must be fulfilled in the given order. May return early based on fulfillment of the waited on expectations.
    ///
    /// - Parameter expectations: The expectations to wait on.
    /// - Parameter timeout: The maximum total time duration to wait on all expectations.
    /// - Parameter enforceOrder: Specifies whether the expectations must be fulfilled in the order
    ///   they are specified in the `expectations` Array. Default is false.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not fulfilled before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not fulfilled before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - SeeAlso: XCTWaiter
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false) async {
        return await withCheckedContinuation { continuation in
            // This function operates by blocking a background thread instead of one owned by libdispatch or by the
            // Swift runtime (as used by Swift concurrency.) To ensure we use a thread owned by neither subsystem, use
            // Foundation's Thread.detachNewThread(_:).
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
                continuation.resume()
            }
        }
    }
#endif
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
    var retryBackoff: TimeAmount = .seconds(0)
    
    func handle(context: JobContext) async throws {
        throw JobError(foo)
    }
    
    func failed(error: Error) {
        RetryJob.didFail?()
    }
}

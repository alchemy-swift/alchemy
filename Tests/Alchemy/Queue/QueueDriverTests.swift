@testable
import Alchemy
import AlchemyTest

final class QueueDriverTests: TestCase<TestApp> {
    private var queue: Queue {
        Queue.default
    }
    
    private lazy var allTests = [
        _testEnqueue,
        _testWorker,
        _testFailure,
        _testRetry,
    ]
    
    func testDatabaseQueue() async throws {
        for test in allTests {
            Database.fake(migrations: [Queue.AddJobsMigration()])
            Queue.register(.database)
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
        for test in allTests {
            Redis.register(.testing)
            Queue.register(.redis)
            
            guard await Redis.default.checkAvailable() else {
                throw XCTSkip()
            }
            
            try await test(#filePath, #line)
            _ = try await Redis.default.send(command: "FLUSHDB").get()
        }
    }
    
    private func _testEnqueue(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await TestJob(foo: "bar").dispatch()
        guard let jobData = try await queue.dequeue(from: ["default"]) else {
            XCTFail("Failed to dequeue a job.", file: file, line: line)
            return
        }
        
        XCTAssertEqual(jobData.jobName, "TestJob", file: file, line: line)
        XCTAssertEqual(jobData.recoveryStrategy, .retry(3), file: file, line: line)
        XCTAssertEqual(jobData.backoff, .seconds(0), file: file, line: line)
        
        let decodedJob = try JobDecoding.decode(jobData)
        guard let testJob = decodedJob as? TestJob else {
            XCTFail("Failed to decode TestJob \(jobData.jobName) \(type(of: decodedJob))", file: file, line: line)
            return
        }
        
        XCTAssertEqual(testJob.foo, "bar", file: file, line: line)
    }
    
    private func _testWorker(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await ConfirmableJob().dispatch()
        
        let exp = expectation(description: "")
        ConfirmableJob.didRun = {
            exp.fulfill()
        }
        
        let loop = EmbeddedEventLoop()
        queue.startWorker(on: loop)
        loop.advanceTime(by: .seconds(5))
        await waitForExpectations(timeout: kMinTimeout)
    }
    
    private func _testFailure(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await FailureJob().dispatch()
        
        let exp = expectation(description: "")
        FailureJob.didFinish = {
            exp.fulfill()
        }
        
        let loop = EmbeddedEventLoop()
        queue.startWorker(on: loop)
        loop.advanceTime(by: .seconds(5))
        
        wait(for: [exp], timeout: kMinTimeout)
        AssertNil(try await queue.dequeue(from: ["default"]))
    }
    
    private func _testRetry(file: StaticString = #filePath, line: UInt = #line) async throws {
        try await TestJob(foo: "bar").dispatch()
        
        let exp = expectation(description: "")
        TestJob.didFail = {
            exp.fulfill()
        }
        
        let loop = EmbeddedEventLoop()
        queue.startWorker(untilEmpty: false, on: loop)
        loop.advanceTime(by: .seconds(5))
        
        wait(for: [exp], timeout: kMinTimeout)
        
        guard let jobData = try await queue.dequeue(from: ["default"]) else {
            XCTFail("Failed to dequeue a job.", file: file, line: line)
            return
        }
        
        XCTAssertEqual(jobData.jobName, "TestJob", file: file, line: line)
        XCTAssertEqual(jobData.attempts, 1, file: file, line: line)
    }
}

private struct FailureJob: Job {
    static var didFinish: (() -> Void)? = nil
    
    func run() async throws {
        throw JobError("foo")
    }
    
    func finished(result: Result<Void, Error>) {
        FailureJob.didFinish?()
    }
}

private struct ConfirmableJob: Job {
    static var didRun: (() -> Void)? = nil
    
    func run() async throws {
        ConfirmableJob.didRun?()
    }
}

private struct TestJob: Job {
    static var didFail: (() -> Void)? = nil
    
    let foo: String
    var recoveryStrategy: RecoveryStrategy = .retry(3)
    var retryBackoff: TimeAmount = .seconds(0)
    
    func run() async throws {
        throw JobError("foo")
    }
    
    func failed(error: Error) {
        TestJob.didFail?()
    }
}

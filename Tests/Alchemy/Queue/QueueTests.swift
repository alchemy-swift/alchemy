//@testable
//import Alchemy
//import AlchemyTest
//
//final class QueueTests: TestCase<TestApp> {
//    private lazy var allTests = [
//        _testEnqueue,
//        _testWorker,
//        _testFailure,
//        _testRetry,
//    ]
//    
//    override func tearDownWithError() throws {
//        // Redis seems to throw on shutdown if it could never connect in the
//        // first place. While this shouldn't be necessary, it is a stopgap
//        // for throwing an error when shutting down unconnected redis.
//        try? app.stop()
//        JobRegistry.reset()
//    }
//    
//    func testConfig() {
//        let config = Queue.Config(queues: [.default: .memory, 1: .memory, 2: .memory], jobs: [.job(TestJob.self)])
//        Queue.configure(with: config)
//        XCTAssertNotNil(Container.resolve(Queue.self, identifier: Queue.Identifier.default))
//        XCTAssertNotNil(Container.resolve(Queue.self, identifier: 1))
//        XCTAssertNotNil(Container.resolve(Queue.self, identifier: 2))
//        XCTAssertTrue(app.registeredJobs.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(TestJob.self) }))
//    }
//    
//    func testJobDecoding() {
//        let fakeData = JobData(id: UUID().uuidString, json: "", jobName: "foo", channel: "bar", recoveryStrategy: .none, retryBackoff: .zero, attempts: 0, backoffUntil: nil)
//        XCTAssertThrowsError(try JobRegistry.decode(fakeData))
//        
//        struct TestJob: Job {
//            let foo: String
//            func run() async throws {}
//        }
//        
//        JobRegistry.register(TestJob.self)
//        let invalidData = JobData(id: "foo", json: "bar", jobName: "TestJob", channel: "foo", recoveryStrategy: .none, retryBackoff: .zero, attempts: 0, backoffUntil: nil)
//        XCTAssertThrowsError(try JobRegistry.decode(invalidData))
//    }
//    
//    func testDatabaseQueue() async throws {
//        do {
//            for test in allTests {
//                try await Database.fake(migrations: [Queue.AddJobsMigration()])
//                Queue.bind(.database)
//                try await test(#filePath, #line)
//            }
//        } catch {
//            print("ERROR \(error)")
//            throw error
//        }
//    }
//    
//    func testMemoryQueue() async throws {
//        for test in allTests {
//            Queue.fake()
//            try await test(#filePath, #line)
//        }
//    }
//    
//    func testRedisQueue() async throws {
//        for test in allTests {
//            RedisClient.bind(.testing)
//            Queue.bind(.redis)
//            
//            guard await Redis.checkAvailable() else {
//                throw XCTSkip()
//            }
//            
//            try await test(#filePath, #line)
//            _ = try await Redis.send(command: "FLUSHDB").get()
//        }
//    }
//    
//    private func _testEnqueue(file: StaticString = #filePath, line: UInt = #line) async throws {
//        try await TestJob(foo: "bar").dispatch()
//        guard let jobData = try await Q.dequeue(from: ["default"]) else {
//            XCTFail("Failed to dequeue a job.", file: file, line: line)
//            return
//        }
//        
//        XCTAssertEqual(jobData.jobName, "TestJob", file: file, line: line)
//        XCTAssertEqual(jobData.recoveryStrategy, .retry(3), file: file, line: line)
//        XCTAssertEqual(jobData.backoff, .seconds(0), file: file, line: line)
//        
//        let decodedJob = try JobRegistry.decode(jobData)
//        guard let testJob = decodedJob as? TestJob else {
//            XCTFail("Failed to decode TestJob \(jobData.jobName) \(type(of: decodedJob))", file: file, line: line)
//            return
//        }
//        
//        XCTAssertEqual(testJob.foo, "bar", file: file, line: line)
//    }
//    
//    private func _testWorker(file: StaticString = #filePath, line: UInt = #line) async throws {
//        try await ConfirmableJob().dispatch()
//        
//        let sema = DispatchSemaphore(value: 0)
//        ConfirmableJob.didRun = {
//            sema.signal()
//        }
//        
//        let loop = EmbeddedEventLoop()
//        Q.startWorker(on: loop)
//        loop.advanceTime(by: .seconds(5))
//        sema.wait()
//    }
//    
//    private func _testFailure(file: StaticString = #filePath, line: UInt = #line) async throws {
//        try await FailureJob().dispatch()
//        
//        let sema = DispatchSemaphore(value: 0)
//        FailureJob.didFinish = {
//            sema.signal()
//        }
//        
//        let loop = EmbeddedEventLoop()
//        Q.startWorker(on: loop)
//        loop.advanceTime(by: .seconds(5))
//        
//        sema.wait()
//        AssertNil(try await Q.dequeue(from: ["default"]))
//    }
//    
//    private func _testRetry(file: StaticString = #filePath, line: UInt = #line) async throws {
//        try await TestJob(foo: "bar").dispatch()
//        
//        let sema = DispatchSemaphore(value: 0)
//        TestJob.didFail = {
//            sema.signal()
//        }
//        
//        let loop = EmbeddedEventLoop()
//        Q.startWorker(untilEmpty: false, on: loop)
//        loop.advanceTime(by: .seconds(5))
//        
//        sema.wait()
//        
//        guard let jobData = try await Q.dequeue(from: ["default"]) else {
//            XCTFail("Failed to dequeue a job.", file: file, line: line)
//            return
//        }
//        
//        XCTAssertEqual(jobData.jobName, "TestJob", file: file, line: line)
//        XCTAssertEqual(jobData.attempts, 1, file: file, line: line)
//    }
//}
//
//private struct FailureJob: Job {
//    static var didFinish: (() -> Void)? = nil
//    
//    func run() async throws {
//        throw JobError("foo")
//    }
//    
//    func finished(result: Result<Void, Error>) {
//        FailureJob.didFinish?()
//    }
//}
//
//private struct ConfirmableJob: Job {
//    static var didRun: (() -> Void)? = nil
//    
//    func run() async throws {
//        ConfirmableJob.didRun?()
//    }
//}
//
//private struct TestJob: Job {
//    static var didFail: (() -> Void)? = nil
//    
//    let foo: String
//    var recoveryStrategy: RecoveryStrategy = .retry(3)
//    var retryBackoff: TimeAmount = .seconds(0)
//    
//    func run() async throws {
//        throw JobError("foo")
//    }
//    
//    func failed(error: Error) {
//        TestJob.didFail?()
//    }
//}

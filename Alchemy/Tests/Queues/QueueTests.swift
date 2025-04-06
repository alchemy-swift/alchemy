@testable
import Alchemy
import AlchemyTesting

@Suite(.mockContainer)
struct QueueTests: TestSuite {
    @Test func jobDecoding() async {
        let fakeData = JobData(payload: Data(), jobName: "", channel: "", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await #expect(throws: Error.self) { try await Jobs.createJob(from: fakeData) }
        Jobs.register(RetryJob.self)
        let invalidData = JobData(payload: Data(), jobName: "RetryJob", channel: "foo", attempts: 0, recoveryStrategy: .none, backoff: .seconds(0))
        await #expect(throws: Error.self) { try await Jobs.createJob(from: invalidData) }
    }

    @Test(arguments: Provider.allCases)
    func enqueue(provider: Provider) async throws {
        guard try await provider.setup() else { return }

        try await RetryJob(foo: "bar").dispatch()
        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            Issue.record("Failed to dequeue a job.")
            return
        }
        
        #expect(jobData.jobName == "RetryJob")
        #expect(jobData.recoveryStrategy == .retry(3))
        #expect(jobData.backoff == .seconds(0))

        let decodedJob = try await Jobs.createJob(from: jobData)
        guard let retryJob = decodedJob as? RetryJob else {
            Issue.record("Failed to decode RetryJob \(jobData.jobName) \(type(of: decodedJob))")
            return
        }
        
        #expect(retryJob.foo == "bar")

        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func worker(provider: Provider) async throws {
        guard try await provider.setup() else { return }

        try await confirmation { confirm in
            ConfirmableJob.didRun = { confirm() }
            try await ConfirmableJob().dispatch()
            App.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }

        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func failure(provider: Provider) async throws {
        guard try await provider.setup() else { return }

        try await confirmation { confirm in
            FailureJob.didFinish = { confirm() }
            try await FailureJob().dispatch()
            App.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }

        #expect(try await Q.dequeue(from: ["default"]) == nil)

        try await provider.teardown()
    }

    @Test(arguments: Provider.allCases)
    func retry(provider: Provider) async throws {
        guard try await provider.setup() else { return }

        try await confirmation { confirm in
            RetryJob.didFail = { confirm() }
            try await RetryJob(foo: "bar").dispatch()
            App.background("queue:work")
            try await Task.sleep(for: .seconds(0.01))
        }

        guard let jobData = try await Q.dequeue(from: ["default"]) else {
            Issue.record("Failed to dequeue a job.")
            return
        }

        #expect(jobData.jobName == "RetryJob")
        #expect(jobData.attempts == 1)

        try await provider.teardown()
    }
}

extension QueueTests {
    enum Provider: CaseIterable {
        case memory
        case database
        case redis

        func setup() async throws -> Bool {
            switch self {
            case .database:
                try await DB.fake(migrations: [Queue.AddJobsMigration()])
                Container.main.set(Queue.database)
            case .memory:
                Q.fake()
            case .redis:
                Container.main.set(RedisClient.integration)
                Container.main.set(Queue.redis)
                guard await Redis.checkAvailable() else { return false }
            }

            return true
        }

        func teardown() async throws {
            guard case .redis = self else { return }
            _ = try await Redis.send(command: "FLUSHDB").get()
        }
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

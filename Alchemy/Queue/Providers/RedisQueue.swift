import NIO
import NIOConcurrencyHelpers
import RediStack

extension Queue {
    /// A queue backed by a Redis connection.
    ///
    /// - Parameter redis: A redis connection to drive this queue.
    ///   Defaults to your default redis connection.
    /// - Returns: The configured queue.
    public static func redis(_ redis: RedisClient = Redis) -> Queue {
        Queue(provider: RedisQueue(redis: redis))
    }

    /// A queue backed by the default Redis connection.
    public static var redis: Queue {
        .redis()
    }
}

/// A queue that persists jobs to a Redis instance.
fileprivate final class RedisQueue: QueueProvider {
    /// The underlying redis connection.
    private let redis: RedisClient
    /// All job data.
    private let dataKey = RedisKey("jobs:data")
    /// All processing jobs.
    private let processingKey = RedisKey("jobs:processing")
    /// All backed off jobs. "job_id" : "backoff:channel"
    private let backoffsKey = RedisKey("jobs:backoffs")
    /// The repeating task used for monitoring backoffs.
    private var backoffTask: RepeatedTask?
    private var lock = NIOLock()

    /// Initialize with a Redis instance to persist jobs to.
    ///
    /// - Parameter redis: The Redis instance.
    init(redis: RedisClient = Redis) {
        self.redis = redis
    }
    
    // MARK: - Queue

    func enqueue(_ job: JobData) async throws {
        try await storeJobData(job)
        _ = try await redis.lpush(job.id, into: key(for: job.channel)).get()
    }
    
    func dequeue(from channel: String) async throws -> JobData? {
        lock.withLock(monitorBackoffs)
        let jobId = try await redis.rpoplpush(from: key(for: channel), to: processingKey, valueType: String.self).get()
        guard let jobId = jobId else {
            return nil
        }
        
        guard let jobString = try await redis.hget(jobId, from: dataKey, as: String.self).get() else {
            throw JobError("Missing job data for key `\(jobId)`.")
        }

        return try JobData(jsonString: jobString)
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) async throws {
        _ = try await redis.lrem(job.id, from: processingKey).get()
        switch outcome {
        case .success, .failed:
            _ = try await redis.hdel(job.id, from: dataKey).get()
        case .retry:
            if let backoffUntil = job.backoffUntil {
                let backoffKey = "\(job.id):\(job.channel)"
                let backoffScore = backoffUntil.timeIntervalSince1970
                try await storeJobData(job)
                _ = try await redis.zadd((backoffKey, backoffScore), to: backoffsKey).get()
            } else {
                try await enqueue(job)
            }
        }
    }

    func shutdown() async throws {
        if let backoffTask {
            let promise: EventLoopPromise<Void> = Loop.makePromise()
            backoffTask.cancel(promise: promise)
            try await promise.futureResult.get()
        }
    }

    // MARK: - Private Helpers
    
    private func key(for channel: String) -> RedisKey {
        RedisKey("jobs:queue:\(channel)")
    }
    
    private func monitorBackoffs() {
        guard backoffTask == nil else { return }

        // TODO: This is failing to die on shutdown. Is there an easier way?
        // TODO: for example, if something should back off, pull the next one, then put the backoff one back.
        let loop = LoopGroup.next()
        let task = loop.scheduleRepeatedAsyncTask(initialDelay: .zero, delay: .seconds(1)) { _ in
            loop.asyncSubmit { [weak self] in
                guard let self else { return }

                // Get and remove backoffs that can be rerun.
                let result = try await self.redis.transaction { conn in
                    let set = RESPValue(from: self.backoffsKey.rawValue)
                    let min = RESPValue(from: 0)
                    let max = RESPValue(from: Date().timeIntervalSince1970)
                    _ = try await conn.send(command: "ZRANGEBYSCORE", with: [set, min, max]).get()
                    _ = try await conn.send(command: "ZREMRANGEBYSCORE", with: [set, min, max]).get()
                }

                guard let values = result.array, let scores = values.first?.array, !scores.isEmpty else {
                    return
                }

                for backoffKey in scores.compactMap(\.string) {
                    let values = backoffKey.split(separator: ":")
                    let jobId = String(values[0])
                    let channel = String(values[1])
                    _ = try await self.redis.lpush(jobId, into: self.key(for: channel)).get()
                }
            }
        }

        backoffTask = task
    }
    
    private func storeJobData(_ job: JobData) async throws {
        let jsonString = try job.jsonString()
        _ = try await redis.hset(job.id, to: jsonString, in: dataKey).get()
    }
}

extension Encodable {
    /// Encode this type into a JSON string.
    fileprivate func jsonString(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        guard let string = try String(data: encoder.encode(self), encoding: .utf8) else {
            throw JobError("Unable to encode `\(Self.self)` to a JSON string.")
        }

        return string
    }
}

extension Decodable {
    /// Initialize this type from a JSON string.
    fileprivate init(jsonString: String, using decoder: JSONDecoder = JSONDecoder()) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw JobError("Unable to initialize `\(Self.self)` from JSON string `\(jsonString)`.")
        }

        self = try decoder.decode(Self.self, from: data)
    }
}

import NIO
import RediStack

/// A queue that persists jobs to a Redis instance.
final class RedisQueue: QueueDriver {
    /// The underlying redis connection.
    private let redis: Redis
    /// All job data.
    private let dataKey = RedisKey("jobs:data")
    /// All processing jobs.
    private let processingKey = RedisKey("jobs:processing")
    /// All backed off jobs. "job_id" : "backoff:channel"
    private let backoffsKey = RedisKey("jobs:backoffs")
    
    /// Initialize with a Redis instance to persist jobs to.
    ///
    /// - Parameter redis: The Redis instance.
    init(redis: Redis = .default) {
        self.redis = redis
        monitorBackoffs()
    }
    
    // MARK: - Queue

    func enqueue(_ job: JobData) async throws {
        try await storeJobData(job)
        _ = try await redis.lpush(job.id, into: key(for: job.channel)).get()
    }
    
    func dequeue(from channel: String) async throws -> JobData? {
        let jobId = try await redis.rpoplpush(from: key(for: channel), to: processingKey, valueType: String.self).get()
        guard let jobId = jobId else {
            return nil
        }
        
        let jobString = try await redis.hget(jobId, from: dataKey, as: String.self).get()
        let unwrappedJobString = try jobString.unwrap(or: JobError("Missing job data for key `\(jobId)`."))
        return try JobData(jsonString: unwrappedJobString)
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
    
    // MARK: - Private Helpers
    
    private func key(for channel: String) -> RedisKey {
        RedisKey("jobs:queue:\(channel)")
    }
    
    private func monitorBackoffs() {
        let loop = Loop.group.next()
        loop.scheduleRepeatedAsyncTask(initialDelay: .zero, delay: .seconds(1)) { (task: RepeatedTask) ->
            EventLoopFuture<Void> in
            return self.redis
                // Get and remove backoffs that can be rerun.
                .transaction { conn -> EventLoopFuture<RESPValue> in
                    let set = RESPValue(from: self.backoffsKey.rawValue)
                    let min = RESPValue(from: 0)
                    let max = RESPValue(from: Date().timeIntervalSince1970)
                    return conn.send(command: "ZRANGEBYSCORE", with: [set, min, max])
                        .flatMap { _ in conn.send(command: "ZREMRANGEBYSCORE", with: [set, min, max]) }
                }
                .map { (value: RESPValue) -> [String] in
                    guard let values = value.array, let scores = values.first?.array, !scores.isEmpty else {
                        return []
                    }
                    
                    return scores.compactMap(\.string)
                }
                .flatMapEach(on: loop) { backoffKey -> EventLoopFuture<Void> in
                    let values = backoffKey.split(separator: ":")
                    let jobId = String(values[0])
                    let channel = String(values[1])
                    let queueList = self.key(for: channel)
                    return self.redis.lpush(jobId, into: queueList).voided()
                }
                .voided()
        }
    }
    
    private func storeJobData(_ job: JobData) async throws {
        let jsonString = try job.jsonString()
        _ = try await redis.hset(job.id, to: jsonString, in: self.dataKey).get()
    }
}

public extension Queue {
    /// A queue backed by a Redis connection.
    ///
    /// - Parameter redis: A redis connection to drive this queue.
    ///   Defaults to your default redis connection.
    /// - Returns: The configured queue.
    static func redis(_ redis: Redis = Redis.default) -> Queue {
        Queue(RedisQueue(redis: redis))
    }
}

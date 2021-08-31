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
    
    // MARK: - Queue

    func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        return self.storeJobData(job)
            .flatMap { self.redis.lpush(job.id, into: self.key(for: job.channel)) }
            .voided()
    }
    
    private func storeJobData(_ job: JobData) -> EventLoopFuture<Void> {
        catchError {
            let jsonString = try job.jsonString()
            return redis.hset(job.id, to: jsonString, in: self.dataKey).voided()
        }
    }
    
    func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        /// Move from queueList to processing
        let queueList = key(for: channel)
        return self.redis.rpoplpush(from: queueList, to: self.processingKey, valueType: String.self)
            .flatMap { jobID in
                guard let jobID = jobID else {
                    return .new(nil)
                }
                
                return self.redis
                    .hget(jobID, from: self.dataKey, as: String.self)
                    .unwrap(orError: JobError("Missing job data for key `\(jobID)`."))
                    .flatMapThrowing { try JobData(jsonString: $0) }
            }
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        switch outcome {
        case .success, .failed:
            // Remove from processing.
            return self.redis.lrem(job.id, from: self.processingKey)
                // Remove job data.
                .flatMap { _ in self.redis.hdel(job.id, from: self.dataKey) }
                .voided()
        case .retry:
            // Remove from processing
            return self.redis.lrem(job.id, from: self.processingKey)
                .flatMap { _ in
                    if let backoffUntil = job.backoffUntil {
                        let backoffKey = "\(job.id):\(job.channel)"
                        let backoffScore = backoffUntil.timeIntervalSince1970
                        return self.storeJobData(job)
                            .flatMap { self.redis.zadd((backoffKey, backoffScore), to: self.backoffsKey) }
                            .voided()
                    } else {
                        return self.enqueue(job)
                    }
                }
        }
    }
    
    private func key(for channel: String) -> RedisKey {
        RedisKey("jobs:queue:\(channel)")
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

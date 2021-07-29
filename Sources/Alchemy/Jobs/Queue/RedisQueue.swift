import NIO
import RediStack

/// A queue that persists jobs to a Redis instance.
public class RedisQueue: Queue {
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
    public init(redis: Redis = Services.redis) {
        self.redis = redis
        monitorBackoffs()
    }
    
    private func monitorBackoffs() {
        Services.eventLoop.scheduleRepeatedAsyncTask(initialDelay: .zero, delay: .seconds(1)) { (task: RepeatedTask) ->
            EventLoopFuture<Void> in
            return self.redis
                .zrangebyscore(from: self.backoffsKey, withMinimumScoreOf: 0)
                .map { (values: [RESPValue]) -> [String] in
                    guard !values.isEmpty else {
                        return []
                    }

                    let now = Int(Date().timeIntervalSince1970)
                    var toRetry: [String] = []
                    for index in 0..<values.count/2 {
                        let position = index * 2
                        guard
                            let jobID = values[position].string,
                            let date = values[position + 1].int
                        else { continue }
                        if date <= now {
                            toRetry.append(jobID)
                        }
                    }

                    return toRetry
                }
                .flatMapEach(on: Services.eventLoop) { backoffKey -> EventLoopFuture<Void> in
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

    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        catchError {
            let jsonString = try job.jsonString()
            let queueList = self.key(for: job.channel)
            // Add job to data
            return self.redis.hset(job.id, to: jsonString, in: self.dataKey)
                // Add to end of specific queue
                .flatMap { _ in self.redis.lpush(job.id, into: queueList) }
                .voided()
        }
    }
    
    public func dequeue(from channels: [String]) -> EventLoopFuture<JobData?> {
        guard let channel = channels.first else {
            return .new(nil)
        }
        
        return dequeue(from: channel)
            .flatMap { result in
                guard let result = result else {
                    return self.dequeue(from: Array(channels.dropFirst()))
                }
                
                return .new(result)
            }
    }
    
    private func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        /// Move from queueList to processing
        let queueList = self.key(for: channel)
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
    
    public func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
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
                        return self.redis.zadd((backoffKey, backoffScore), to: self.backoffsKey)
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

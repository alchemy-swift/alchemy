import Foundation
import RediStack

/// A queue that persists jobs to a Redis instance.
public class RedisQueue: Queue {
    private let redis: Redis
    private let dataKey = RedisKey("jobs:data")
    private let processingKey = RedisKey("jobs:processing")
    
    /// Initialize with a Redis instance to persist jobs to.
    ///
    /// - Parameter redis: The Redis instance.
    public init(redis: Redis) {
        self.redis = redis
    }
    
    // MARK: - Queue

    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        catchError {
            let jsonString = try job.jsonString()
            let queueList = self.key(for: job.queueName)
            // Add job to data
            return self.redis.hset(job.id, to: jsonString, in: self.dataKey)
                // Add to end of specific queue
                .flatMap { _ in self.redis.lpush(job.id, into: queueList) }
                .voided()
        }
    }
    
    public func dequeue(from queueName: String) -> EventLoopFuture<JobData?> {
        /// Move from queueList to processing
        let queueList = self.key(for: queueName)
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
            // Remove from processing.
            return self.redis.lrem(job.id, from: self.processingKey)
                // Add back to queue
                .flatMap { _ in self.enqueue(job) }
        }
    }
    
    private func key(for queueName: String) -> RedisKey {
        RedisKey("jobs:queue:\(queueName)")
    }
}

import Foundation
import NIO

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down.
public final class MockQueue: Queue {
    @Locked private var jobs: [JobID: JobData] = [:]
    @Locked private var pending: [String: [JobID]] = [:]
    @Locked private var reserved: [String: [JobID]] = [:]
    
    public init() {}
    
    // MARK: - Queue
    
    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        self.jobs[job.id] = job
        self.append(id: job.id, on: job.channel, dict: &self.pending)
        return .new()
    }
    
    public func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        guard let id = self.pending[channel]?.popFirst() else {
            return .new(nil)
        }
        
        self.append(id: id, on: channel, dict: &self.reserved)
        return .new(self.jobs[id])
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        switch outcome {
        case .success, .failed:
            self.reserved[job.channel]?.removeAll(where: { $0 == job.id })
            self.jobs.removeValue(forKey: job.id)
        case .retry:
            self.jobs[job.id]?.attempts += 1
        }
        return .new()
    }
    
    private func append(id: JobID, on channel: String, dict: inout [String: [JobID]]) {
        var array = dict[channel] ?? []
        array.append(id)
        dict[channel] = array
    }
}

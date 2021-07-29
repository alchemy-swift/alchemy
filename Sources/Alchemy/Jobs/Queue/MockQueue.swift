import Foundation
import NIO

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down.
public final class MockQueue: Queue {
    @Locked private var jobs: [JobID: JobData] = [:]
    @Locked private var pending: [String: Locked<[JobID]>] = [:]
    @Locked private var reserved: [String: Locked<[JobID]>] = [:]
    
    public init() {}
    
    // MARK: - Queue
    
    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        jobs[job.id] = job
        append(id: job.id, on: job.channel, dict: &pending)
        return .new()
    }
    
    public func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        guard
            let id = pending[channel]?.wrappedValue.popFirst(where: { (thing: JobID) -> Bool in
                return !(jobs[thing]?.inBackoff ?? false)
            }),
            let job = jobs[id]
        else {
            return .new(nil)
        }
        
        append(id: id, on: job.channel, dict: &reserved)
        return .new(job)
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        switch outcome {
        case .success, .failed:
            reserved[job.channel]?.wrappedValue.removeAll(where: { $0 == job.id })
            jobs.removeValue(forKey: job.id)
        case .retry:
            jobs[job.id] = job
        }
        
        return .new()
    }
    
    private func append(id: JobID, on channel: String, dict: inout [String: Locked<[JobID]>]) {
        var array = dict[channel] ?? Locked(wrappedValue: [])
        array.wrappedValue.append(id)
        dict[channel] = array
    }
}

extension JobData {
    var inBackoff: Bool {
        guard let date = backoffUntil else {
            return false
        }
        
        return date > Date()
    }
    
    func nextRetryDate() -> Date? {
        return backoffSeconds > 0 ? Date().addingTimeInterval(TimeInterval(backoffSeconds)) : nil
    }
}

extension Array {
    mutating func popFirst(where conditional: (Element) -> Bool) -> Element? {
        if let firstIndex = firstIndex(where: conditional) {
            return remove(at: firstIndex)
        } else {
            return nil
        }
    }
}

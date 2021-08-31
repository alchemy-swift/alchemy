import Foundation
import NIO

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down. Useful for tests.
final class MockQueue: QueueDriver {
    private var jobs: [JobID: JobData] = [:]
    private var pending: [String: [JobID]] = [:]
    private var reserved: [String: [JobID]] = [:]
    
    private let lock = NSRecursiveLock()
    
    init() {}
    
    // MARK: - Queue
    
    func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.id] = job
        append(id: job.id, on: job.channel, dict: &pending)
        return .new()
    }
    
    func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        lock.lock()
        defer { lock.unlock() }
        
        guard
            let id = pending[channel]?.popFirst(where: { (thing: JobID) -> Bool in
                let isInBackoff = jobs[thing]?.inBackoff ?? false
                return !isInBackoff
            }),
            let job = jobs[id]
        else {
            return .new(nil)
        }
        
        append(id: id, on: job.channel, dict: &reserved)
        return .new(job)
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        lock.lock()
        defer { lock.unlock() }
        
        switch outcome {
        case .success, .failed:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            jobs.removeValue(forKey: job.id)
            return .new()
        case .retry:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            return enqueue(job)
        }
    }
    
    private func append(id: JobID, on channel: String, dict: inout [String: [JobID]]) {
        var array = dict[channel] ?? []
        array.append(id)
        dict[channel] = array
    }
}

extension Queue {
    /// An in memory queue. Useful primarily for testing.
    public static func mock() -> Queue {
        Queue(MockQueue())
    }
}

extension Array {
    /// Pop the first element that satisfies the given conditional.
    ///
    /// - Parameter conditional: A conditional closure.
    /// - Returns: The first matching element, or nil if no elements
    ///   match.
    fileprivate mutating func popFirst(where conditional: (Element) -> Bool) -> Element? {
        if let firstIndex = firstIndex(where: conditional) {
            return remove(at: firstIndex)
        } else {
            return nil
        }
    }
}

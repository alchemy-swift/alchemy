import Foundation
import NIO

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down. Useful for tests.
public final class MemoryQueue: QueueDriver {
    var jobs: [JobID: JobData] = [:]
    var pending: [String: [JobID]] = [:]
    var reserved: [String: [JobID]] = [:]
    
    private let lock = NSRecursiveLock()
    
    init() {}
    
    // MARK: - Queue
    
    public func enqueue(_ job: JobData) async throws {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.id] = job
        append(id: job.id, on: job.channel, dict: &pending)
    }
    
    public func dequeue(from channel: String) async throws -> JobData? {
        lock.lock()
        defer { lock.unlock() }
        
        guard
            let id = pending[channel]?.popFirst(where: { (thing: JobID) -> Bool in
                let isInBackoff = jobs[thing]?.inBackoff ?? false
                return !isInBackoff
            }),
            let job = jobs[id]
        else {
            return nil
        }
        
        append(id: id, on: job.channel, dict: &reserved)
        return job
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) async throws {
        lock.lock()
        defer { lock.unlock() }
        
        switch outcome {
        case .success, .failed:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            jobs.removeValue(forKey: job.id)
        case .retry:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            try await enqueue(job)
        }
    }
    
    private func append(id: JobID, on channel: String, dict: inout [String: [JobID]]) {
        var array = dict[channel] ?? []
        array.append(id)
        dict[channel] = array
    }
}

extension Queue {
    /// An in memory queue.
    public static var memory: Queue {
        Queue(MemoryQueue())
    }

    /// Fake the queue with an in memory queue. Useful for testing.
    ///
    /// - Parameter id: The identifier of the queue to fake. Defaults to
    ///   `default`.
    /// - Returns: A `MemoryQueue` for verifying test expectations.
    @discardableResult
    public static func fake(_ identifier: Identifier = .default) -> MemoryQueue {
        let mock = MemoryQueue()
        let q = Queue(mock)
        register(identifier, q)
        return mock
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

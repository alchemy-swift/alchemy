import Foundation
import NIO

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down. Useful for tests.
final class MockQueue: QueueDriver {
    var jobs: [JobID: JobData] = [:]
    var pending: [String: [JobID]] = [:]
    var reserved: [String: [JobID]] = [:]
    
    private let lock = NSRecursiveLock()
    
    init() {}
    
    // MARK: - Queue
    
    func enqueue(_ job: JobData) async throws {
        lock.lock()
        defer { lock.unlock() }
        
        jobs[job.id] = job
        append(id: job.id, on: job.channel, dict: &pending)
    }
    
    func dequeue(from channel: String) async throws -> JobData? {
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
    
    func complete(_ job: JobData, outcome: JobOutcome) async throws {
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
    /// An in memory queue. Useful primarily for testing.
    @discardableResult
    static func mock(_ name: String? = nil) -> MockQueue {
        let mock = MockQueue()
        let q = Queue(mock)
        if let name = name {
            config(name, q)
        } else {
            config(default: q)
        }
        
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

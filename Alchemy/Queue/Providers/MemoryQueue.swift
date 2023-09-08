import NIOConcurrencyHelpers

extension Queue {
    /// An in memory queue.
    public static var memory: Queue {
        Queue(provider: MemoryQueue())
    }

    /// Fake the queue with an in memory queue. Useful for testing.
    ///
    /// - Parameter id: The identifier of the queue to fake. Defaults to
    ///   `default`.
    /// - Returns: A `MemoryQueue` for verifying test expectations.
    @discardableResult
    public static func fake(_ id: Identifier? = nil) -> MemoryQueue {
        let mock = MemoryQueue()
        Container.register(Queue(provider: mock), id: id).singleton()
        return mock
    }
}

/// A queue that persists jobs to memory. Jobs will be lost if the
/// app shuts down. Useful for tests.
public actor MemoryQueue: QueueProvider {
    typealias JobID = String

    var jobs: [JobID: JobData] = [:]
    private var pending: [String: [JobID]] = [:]
    private var reserved: [String: [JobID]] = [:]
    private let lock = NIOLock()

    // MARK: - Queue
    
    public func enqueue(_ job: JobData) async throws {
        jobs[job.id] = job
        append(id: job.id, on: job.channel, dict: &pending)
    }
    
    public func dequeue(from channel: String) async throws -> JobData? {
        guard 
            let index = pending[channel]?.firstIndex(where: { id in
                let isInBackoff = jobs[id]?.inBackoff ?? false
                return !isInBackoff
            }),
            let id = pending[channel]?.remove(at: index),
            let job = jobs[id]
        else {
            return nil
        }

        append(id: id, on: job.channel, dict: &reserved)
        return job
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) async throws {
        switch outcome {
        case .success, .failed:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            jobs.removeValue(forKey: job.id)
        case .retry:
            reserved[job.channel]?.removeAll(where: { $0 == job.id })
            try await enqueue(job)
        }
    }

    public func shutdown() {
        jobs = [:]
        pending = [:]
        reserved = [:]
    }

    private func append(id: JobID, on channel: String, dict: inout [String: [JobID]]) {
        var array = dict[channel] ?? []
        array.append(id)
        dict[channel] = array
    }
}

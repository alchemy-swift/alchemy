import Foundation
import NIO

public struct MemoryJob: PersistedJob {

    public let id: JobID
    public let name: String
    public var payload: JSONData
    public var attempts: Int = 0

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case attempts
        case payload
    }

    init(id: JobID, name: String, payload: Data) {
        self.id = id
        self.name = name
        self.payload = JSONData(data: payload)
    }
}

public class MemoryQueue: Queue {
    public typealias QueueItem = MemoryJob

    public var eventLoop: EventLoop

    var isEmpty: Bool {
        return self.pending.isEmpty
    }

    private var jobs: [JobID: MemoryJob] = [:]

    private var delayed: [JobID] = []

    private var pending: [JobID] = []

//    private var failed: [Job] = []

    public init(eventLoop: EventLoop = Services.eventLoop) {
        self.eventLoop = eventLoop
    }

    @discardableResult
    public func enqueue<T: Job>(_ type: T.Type, _ payload: T.Payload) -> EventLoopFuture<Void> {
        let identifier = UUID().uuidString
        let payloadData = try! T.serializePayload(payload)
        return self.requeue(
            MemoryJob(
                id: identifier,
                name: T.name,
                payload: payloadData
            )
        )
    }

    public func dequeue() -> EventLoopFuture<MemoryJob?> {
        guard let jobId = self.nextId(),
            let job = self.jobs[jobId] else {
            return eventLoop.makeSucceededFuture(nil)
        }
        return eventLoop.makeSucceededFuture(job)
    }

    public func complete(_ item: MemoryJob, success: Bool) -> EventLoopFuture<Void> {
        self.jobs[item.id] = nil
        return eventLoop.makeSucceededFuture(())
    }

    public func requeue(_ item: MemoryJob) -> EventLoopFuture<Void> {
        self.jobs[item.id] = item
//        if item.job is PeriodicJob || item.job is ScheduledJob {
//            self.delayed.append(item.id)
//        }
//        else {
            self.pending.append(item.id)
//        }
        return eventLoop.makeSucceededFuture(())
    }

    private func nextId() -> JobID? {
//        let nextPeriodicJobId = self.delayed.first {
//            if let nextPeriodicJob = self.jobs[$0]?.job as? PeriodicJob {
//                return nextPeriodicJob.shouldProcess
//            }
//            return false
//        }
//        if let nextJobId = nextPeriodicJobId {
//            return nextJobId
//        }
        if !isEmpty {
            return self.pending.removeFirst()
        }
        return nil
    }
}

//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import NIO

public class MemoryQueue: Queue {

    @Inject public var eventLoop: EventLoop

    var isEmpty: Bool {
        return self.pending.isEmpty
    }

    private var jobs: [JobID: PersistedJob] = [:]

    private var delayed: [JobID] = []

    private var pending: [JobID] = []

    private var failed: [Job] = []

    public init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    @discardableResult
    public func enqueue<T: Job>(_ job: T) -> EventLoopFuture<Void> {
        let identifier = UUID().uuidString
        let runner = try! PersistedJob(id: identifier, payload: job)
        return self.requeue(runner)
    }

    public func dequeue() -> EventLoopFuture<PersistedJob?> {
        guard let jobId = self.nextId(),
            let job = self.jobs[jobId] else {
            return eventLoop.makeSucceededFuture(nil)
        }
        return eventLoop.makeSucceededFuture(job)
    }

    public func complete(_ item: PersistedJob, success: Bool) -> EventLoopFuture<Void> {
        self.jobs[item.id] = nil
        return eventLoop.makeSucceededFuture(())
    }

    public func requeue(_ item: PersistedJob) -> EventLoopFuture<Void> {
        self.jobs[item.id] = item
        if item.job is PeriodicJob || item.job is ScheduledJob {
            self.delayed.append(item.id)
        }
        else {
            self.pending.append(item.id)
        }
        return eventLoop.makeSucceededFuture(())
    }

    private func nextId() -> JobID? {
        let nextPeriodicJobId = self.delayed.first {
            if let nextPeriodicJob = self.jobs[$0]?.job as? PeriodicJob {
                return nextPeriodicJob.shouldProcess
            }
            return false
        }
        if let nextJobId = nextPeriodicJobId {
            return nextJobId
        }
        return self.pending.first
    }

    public static var factory: (Container) throws -> MemoryQueue = { _ in
        MemoryQueue(eventLoop: Services.eventLoop)
    }
}

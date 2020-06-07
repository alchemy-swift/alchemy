//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation
import NIO

class MemoryQueue: Queue {

    var isEmpty: Bool {
        return self.pending.isEmpty
    }

    private var jobs: [JobID: Job] = [:]

    private var delayed: [JobID] = []

    private var pending: [JobID] = []

    let eventLoop: EventLoop

    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }

    func enqueue(_ job: Job) -> Future<Void> {
        let identifier = UUID().uuidString
        return self.requeue((id: identifier, job: job))
    }

    public func dequeue() -> Future<PersistedJob?> {
        guard let jobId = self.nextId(),
            let job = self.jobs[jobId] else {
            return eventLoop.makeSucceededFuture(nil)
        }
        return eventLoop.makeSucceededFuture((id: jobId, job: job))
    }

    public func complete(_ job: JobID) -> Future<Void> {
        self.jobs[job] = nil
        return eventLoop.makeSucceededFuture(())
    }

    public func requeue(_ job: PersistedJob) -> Future<Void> {
        self.jobs[job.id] = job.job
        if job is PeriodicJob || job is ScheduledJob {
            self.delayed.append(job.id)
        }
        else {
            self.pending.append(job.id)
        }
        return eventLoop.makeSucceededFuture(())
    }

    private func nextId() -> JobID? {
        var nextJobId: JobID = self.delayed.filter { self.jobs[$0]?.nextTime > Date().timeIntervalSince1970 }
        if nextJobId == nil {
            nextJobId = self.pending.first
        }
        return nextJobId
    }
}

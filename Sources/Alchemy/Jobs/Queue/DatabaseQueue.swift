//
//  File.swift
//  
//
//  Created by Chris Anderson on 6/7/20.
//

import Foundation

// should be unique


// queue
// payload
// attempts
// reserved
// reserved_at

struct FailedJob: Model {
    var id: Int?
    var name: String
    var payload: Data

    init(job: DatabaseJob) {
        self.name = job.name
        self.payload = job.payload
    }
}

public struct DatabaseJob: Model, PersistedJob {
    public static var tableName: String = "jobs"

    public var id: Int?
    public var name: String
    public var payload: Data
    public var attempts: Int // How many times a job has been run
    var reserved: Bool // If a worker is currently processing
    var reservedAt: Date? // When the worker started the process

    init(name: String, payload: Data) {
        self.name = name
        self.payload = payload
        self.attempts = 0
        self.reserved = false
    }
}


public class DatabaseQueue: Queue {
    public typealias QueueItem = DatabaseJob

    private var database: Database
    public var eventLoop: EventLoop

    public init(
        database: Database = Services.db,
        eventLoop: EventLoop = Services.eventLoop
    ) {
        self.database = database
        self.eventLoop = eventLoop
    }

    public func enqueue<T: Job>(_ type: T.Type, _ payload: T.Payload) -> EventLoopFuture<Void> {
        let job = DatabaseJob(
            name: T.name,
            payload: try! T.serializePayload(payload)
        )
        return requeue(job)
    }

    public func dequeue() -> EventLoopFuture<DatabaseJob?> {
        DatabaseJob.query()
            .where("reserved" == false)
            .getFirst()
            .flatMap { (job: DatabaseJob?) in
                guard var updateJob = job else {
                    return self.eventLoop.makeSucceededFuture(nil)
                }
                updateJob.reserved = true
                updateJob.reservedAt = Date()
                return updateJob.save().map { $0 }
            }
    }

    public func complete(_ item: DatabaseJob, success: Bool) -> EventLoopFuture<Void> {
        if success {
            return DatabaseJob.query()
                .where("id" == item.id)
                .delete()
                .voided()
        }
        else {
            return FailedJob(job: item)
                .save()
                .voided()
        }
    }

    public func requeue(_ item: DatabaseJob) -> EventLoopFuture<Void> {
        return item.save().voided()
    }
}

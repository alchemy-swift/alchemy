import Foundation

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

    @discardableResult
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
            .firstModel()
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

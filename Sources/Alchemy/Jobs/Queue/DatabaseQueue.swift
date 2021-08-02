import Foundation

/// A queue that persists jobs to a database.
public class DatabaseQueue: Queue {
    private let database: Database
    
    /// Initialize with a database, to which Jobs will be persisted.
    ///
    /// - Parameters:
    ///   - database: The database.
    public init(database: Database = Services.db) {
        self.database = database
    }
    
    // MARK: - Queue
    
    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        JobModel(jobData: job).insert(db: database).voided()
    }

    public func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        return database.runRawQuery(
            """
            UPDATE jobs
            SET reserved = true, reserved_at = NOW()
            WHERE id = (
                SELECT id
                FROM jobs
                WHERE NOT reserved
                AND channel = ?
                AND (backoff_until IS NULL OR backoff_until < NOW())
                ORDER BY queued_at
                FOR UPDATE SKIP LOCKED
                LIMIT 1
            )
            RETURNING jobs.*
            """,
            values: [.string(channel)]
        )
        .flatMapEachThrowing { try $0.decode(JobModel.self) }
        .mapEach { $0.toJobData() }
        .map { $0.first }
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        switch outcome {
        case .success, .failed:
            return JobModel.query()
                .where("id" == job.id)
                .where("channel" == job.channel)
                .delete()
                .voided()
        case .retry:
            return JobModel(jobData: job).update().voided()
        }
    }
}

// MARK: - Models

private struct JobModel: Model {
    static var tableName: String = "jobs"

    var id: String?
    let jobName: String
    let channel: String
    let json: JSONString
    let recoveryStrategy: RecoveryStrategy
    let backoffSeconds: Int
    
    var attempts: Int
    var reserved: Bool
    var reservedAt: Date?
    var queuedAt: Date?
    var backoffUntil: Date?

    init(jobData: JobData) {
        id = jobData.id
        jobName = jobData.jobName
        channel = jobData.channel
        json = jobData.json
        attempts = jobData.attempts
        recoveryStrategy = jobData.recoveryStrategy
        backoffSeconds = jobData.backoffSeconds
        backoffUntil = jobData.backoffUntil
        reserved = false
    }
    
    func toJobData() -> JobData {
        return JobData(
            id: (try? getID()) ?? "N/A",
            json: json,
            jobName: jobName,
            channel: channel,
            recoveryStrategy: recoveryStrategy,
            retryBackoff: .seconds(Int64(backoffSeconds)),
            attempts: attempts,
            backoffUntil: backoffUntil
        )
    }
}

// MARK: - Migrations

extension DatabaseQueue {
    /// A Migration for the table used by DatabaseQueue to store jobs.
    public struct Migration: Alchemy.Migration {
        public var name: String { "CreateJobs" }
        
        public init() {}
        
        public func up(schema: Schema) {
            schema.create(table: "jobs") {
                $0.string("id").primary()
                $0.string("job_name").notNull()
                $0.string("channel").notNull()
                $0.string("json", length: .unlimited).notNull()
                $0.json("recovery_strategy").notNull()
                $0.int("attempts").notNull()
                $0.bool("reserved").notNull()
                $0.date("reserved_at")
                $0.date("queued_at").notNull().defaultNow()
                $0.date("backoff_until")
                $0.bigInt("backoff_seconds")
                $0.timestamps()
            }
        }
        
        public func down(schema: Schema) {
            schema.drop(table: "jobs")
        }
    }
}

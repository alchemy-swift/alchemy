import Foundation

extension Queue {
    /// A queue backed by an SQL database.
    ///
    /// - Parameter database: A database to drive this queue with.
    ///   Defaults to your default database.
    /// - Returns: The configured queue.
    public static func database(_ db: Database = DB) -> Queue {
        Queue(provider: DatabaseQueue(db: db))
    }

    /// A queue backed by the default SQL database.
    public static var database: Queue {
        .database()
    }
}

/// A queue that persists jobs to a database.
private final class DatabaseQueue: QueueProvider {
    /// Represents the table of jobs backing a `DatabaseQueue`.
    @Model
    struct JobModel {
        static var table = "jobs"

        var id: String
        let jobName: String
        let channel: String
        let payload: Data
        let recoveryStrategy: Job.RecoveryStrategy
        let backoffSeconds: Int

        var attempts: Int
        var reserved: Bool
        var reservedAt: Date?
        var queuedAt: Date?
        var backoffUntil: Date?

        init(jobData: JobData) {
            jobName = jobData.jobName
            channel = jobData.channel
            payload = jobData.payload
            attempts = jobData.attempts
            recoveryStrategy = jobData.recoveryStrategy
            backoffSeconds = jobData.backoff.seconds
            backoffUntil = jobData.backoffUntil
            reserved = false
            id = jobData.id
        }

        func toJobData() throws -> JobData {
            JobData(
                id: id,
                payload: payload,
                jobName: jobName,
                channel: channel,
                attempts: attempts, 
                recoveryStrategy: recoveryStrategy,
                backoff: .seconds(Int64(backoffSeconds)),
                backoffUntil: backoffUntil
            )
        }
    }

    /// The database backing this queue.
    let db: Database

    /// Initialize with a database, to which Jobs will be persisted.
    ///
    /// - Parameters:
    ///   - database: The database.
    init(db: Database = DB) {
        self.db = db
    }
    
    // MARK: - Queue
    
    func enqueue(_ job: JobData) async throws {
        _ = try await JobModel(jobData: job).insertReturn(on: db)
    }

    func dequeue(from channel: String) async throws -> JobData? {
        return try await db.transaction { conn in
            let job = try await JobModel.query(on: conn)
                .where("reserved" != true)
                .where("channel" == channel)
                .where { $0.whereNull("backoff_until").orWhere("backoff_until" < Date()) }
                .orderBy("queued_at")
                .limit(1)
                .lock(for: .update, option: .skipLocked)
                .first()

            return try await job?.update(on: conn) {
                $0.reserved = true
                $0.reservedAt = Date()
            }.toJobData()
        }
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) async throws {
        switch outcome {
        case .success, .failed:
            _ = try await JobModel.query(on: db)
                .where("id" == job.id)
                .where("channel" == job.channel)
                .delete()
        case .retry:
            _ = try await JobModel(jobData: job).update(on: db)
        }
    }

    func shutdown() {}
}

// MARK: - Migration

extension Queue {
    /// A Migration for the table used by DatabaseQueue to store jobs.
    public struct AddJobsMigration: Migration {
        public init() {}

        public func up(db: Database) async throws {
            try await db.createTable("jobs") {
                $0.string("id").primary()
                $0.string("job_name").notNull()
                $0.string("channel").notNull()
                $0.json("payload").notNull()
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

        public func down(db: Database) async throws {
            try await db.dropTable("jobs")
        }
    }
}

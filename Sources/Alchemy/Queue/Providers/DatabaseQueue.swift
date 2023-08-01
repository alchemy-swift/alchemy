import Foundation

/// A queue that persists jobs to a database.
final class DatabaseQueue: QueueProvider {
    /// The database backing this queue.

    private var db: Database { DB(id) }
    private let id: Database.Identifier

    /// Initialize with a database, to which Jobs will be persisted.
    ///
    /// - Parameters:
    ///   - database: The database.
    init(id: Database.Identifier = .default) {
        self.id = id
    }
    
    // MARK: - Queue
    
    func enqueue(_ job: JobData) async throws {
        _ = try await JobModel(jobData: job).insertReturn(db: db)
    }

    func dequeue(from channel: String) async throws -> JobData? {
        return try await db.transaction { conn in
            let job = try await JobModel.query(db: conn)
                .where("reserved" != true)
                .where("channel" == channel)
                .where { $0.whereNull("backoff_until").orWhere("backoff_until" < Date()) }
                .orderBy("queued_at")
                .limit(1)
                .lock(for: .update, option: .skipLocked)
                .first()
            
            return try await job?.update(db: conn) {
                $0.reserved = true
                $0.reservedAt = Date()
            }.toJobData()
        }
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) async throws {
        switch outcome {
        case .success, .failed:
            _ = try await JobModel.query(db: db)
                .where("id" == job.id)
                .where("channel" == job.channel)
                .delete()
        case .retry:
            _ = try await JobModel(jobData: job).update(db: db)
        }
    }

    func shutdown() {}
}

extension Queue {
    /// A queue backed by an SQL database.
    ///
    /// - Parameter database: A database to drive this queue with.
    ///   Defaults to your default database.
    /// - Returns: The configured queue.
    public static func database(_ id: Database.Identifier = .default) -> Queue {
        Queue(provider: DatabaseQueue(id: id))
    }
    
    /// A queue backed by the default SQL database.
    public static var database: Queue {
        .database()
    }
}

// MARK: - Models

/// Represents the table of jobs backing a `DatabaseQueue`.
struct JobModel: Model {
    static var table = "jobs"

    var id: PK<String> = .new
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
        id = .existing(jobData.id)
        jobName = jobData.jobName
        channel = jobData.channel
        json = jobData.json
        attempts = jobData.attempts
        recoveryStrategy = jobData.recoveryStrategy
        backoffSeconds = jobData.backoff.seconds
        backoffUntil = jobData.backoffUntil
        reserved = false
    }
    
    func toJobData() throws -> JobData {
        JobData(
            id: try id(),
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

extension Queue {
    /// A Migration for the table used by DatabaseQueue to store jobs.
    public struct AddJobsMigration: Migration {
        public init() {}

        public func up(db: Database) async throws {
            try await db.create(table: "jobs") {
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

        public func down(db: Database) async throws {
            try await db.drop(table: "jobs")
        }
    }
}

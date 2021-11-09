import Foundation

/// A queue that persists jobs to a database.
final class DatabaseQueue: QueueDriver {
    /// The database backing this queue.
    private let database: Database
    
    /// Initialize with a database, to which Jobs will be persisted.
    ///
    /// - Parameters:
    ///   - database: The database.
    init(database: Database = .default) {
        self.database = database
    }
    
    // MARK: - Queue
    
    func enqueue(_ job: JobData) async throws {
        _ = try await JobModel(jobData: job).insert(db: database)
    }

    func dequeue(from channel: String) async throws -> JobData? {
        return try await database.transaction { conn in
            let job = try await JobModel.query(database: conn)
                .where("reserved" != true)
                .where("channel" == channel)
                .where { $0.whereNull(key: "backoff_until").orWhere("backoff_until" < Date()) }
                .orderBy(column: "queued_at")
                .limit(1)
                .lock(for: .update, option: .skipLocked)
                .firstModel()
            
            return try await job?.update(db: conn) {
                $0.reserved = true
                $0.reservedAt = Date()
            }.toJobData()
        }
    }
    
    func complete(_ job: JobData, outcome: JobOutcome) async throws {
        switch outcome {
        case .success, .failed:
            _ = try await JobModel.query(database: database)
                .where("id" == job.id)
                .where("channel" == job.channel)
                .delete()
        case .retry:
            _ = try await JobModel(jobData: job).update(db: database)
        }
    }
}

public extension Queue {
    /// A queue backed by an SQL database.
    ///
    /// - Parameter database: A database to drive this queue with.
    ///   Defaults to your default database.
    /// - Returns: The configured queue.
    static func database(_ database: Database = .default) -> Queue {
        Queue(DatabaseQueue(database: database))
    }
}

// MARK: - Models

/// Represents the table of jobs backing a `DatabaseQueue`.
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

extension Queue {
    /// A Migration for the table used by DatabaseQueue to store jobs.
    public struct AddJobsMigration: Migration {
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

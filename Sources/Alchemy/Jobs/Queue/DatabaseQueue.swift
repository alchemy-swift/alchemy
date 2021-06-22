import Foundation

/// A queue that persists jobs to a database.
public class DatabaseQueue: Queue {
    private let database: Database
    private let saveFailedJobs: Bool
    
    /// Initialize with a database, to which Jobs will be persisted.
    ///
    /// - Parameters:
    ///   - database: The database.
    ///   - saveFailedJobs: If true, failed jobs will be written to a
    ///     separate table. Please run
    ///     `DatabaseQueue.FailedJobsMigration` if using this feature.
    public init(database: Database = Services.db, saveFailedJobs: Bool = false) {
        self.database = database
        self.saveFailedJobs = saveFailedJobs
    }
    
    // MARK: - Queue
    
    public func enqueue(_ job: JobData) -> EventLoopFuture<Void> {
        JobModel(jobData: job).insert(db: self.database).voided()
    }

    public func dequeue(from channel: String) -> EventLoopFuture<JobData?> {
        JobModel.query()
            .where("channel" == channel)
            .where("reserved" == false)
            .firstModel()
            .flatMap { job in
                guard var updateJob = job else {
                    return .new(nil)
                }
                
                updateJob.reserved = true
                updateJob.reservedAt = Date()
                return updateJob.save()
                    .map { $0.toJobData() }
            }
    }
    
    public func complete(_ job: JobData, outcome: JobOutcome) -> EventLoopFuture<Void> {
        switch outcome {
        case .success, .failed:
            return JobModel.query()
                .where("id" == job.id)
                .where("channel" == job.channel)
                .delete()
                .voided()
                .map { self.processFailedJob(job) }
        case .retry:
            return JobModel(jobData: job).update().voided()
        }
    }
    
    private func processFailedJob(_ job: JobData) {
        if self.saveFailedJobs {
            // Fire and forget so it doesn't cause errors in the
            // completion chain.
            FailedJobModel(job: job)
                .insert()
                .whenFailure { Log.error("Encountered error saving a failed Job: \($0).") }
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
    
    var attempts: Int
    var reserved: Bool // If a worker is currently processing
    var reservedAt: Date? // When the worker started the process

    init(jobData: JobData) {
        self.id = jobData.id
        self.jobName = jobData.jobName
        self.channel = jobData.channel
        self.json = jobData.json
        self.attempts = jobData.attempts
        self.recoveryStrategy = jobData.recoveryStrategy
        self.reserved = false
    }
    
    func toJobData() -> JobData {
        JobData(
            id: (try? self.getID()) ?? "N/A",
            json: self.json,
            jobName: self.jobName,
            channel: self.channel,
            recoveryStrategy: self.recoveryStrategy,
            attempts: self.attempts
        )
    }
}

private struct FailedJobModel: Model {
    var id: String?
    let name: String
    let jobData: String

    init(job: JobData) {
        self.id = job.id
        self.name = job.jobName
        self.jobData = job.json
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
                $0.timestamps()
            }
        }
        
        public func down(schema: Schema) {
            schema.drop(table: "jobs")
        }
    }
    
    /// A Migration for the table used by DatabaseQueue to store
    /// failed jobs. Only needed if `saveFailedJobs` is enabled.
    public struct FailedJobsMigration: Alchemy.Migration {
        public func up(schema: Schema) {
            schema.create(table: "jobs_failed") {
                $0.string("id").primary()
                $0.string("name").notNull()
                $0.string("job_data", length: .unlimited).notNull()
            }
        }
        
        public func down(schema: Schema) {
            schema.drop(table: "jobs_failed")
        }
    }
}

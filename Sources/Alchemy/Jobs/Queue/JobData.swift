import NIO

public typealias JobID = String
public typealias JSONString = String

/// Represents a persisted Job, contains the serialized Job as well
/// as some additional info for `Queue`s & `QueueWorker`s.
public struct JobData: Codable {
    /// The unique id of this job, by default this is a UUID string.
    public let id: JobID
    /// The serialized Job this persists.
    public var json: JSONString
    /// The Job name.
    public let jobName: String
    /// The channel this is associated with.
    public let channel: String
    /// The recovery strategy to enact, should this Job fail to run.
    public let recoveryStrategy: RecoveryStrategy
    /// How long should be waited before retrying a Job after a
    /// failure.
    public let backoffSeconds: Int
    /// Don't run this again until this time.
    public var backoffUntil: Date?
    /// The number of attempts this Job has been attempted.
    public var attempts: Int
    
    /// Can this job be retried.
    public var canRetry: Bool {
        self.attempts <= self.recoveryStrategy.maximumRetries
    }
    
    /// Create with a Job, id, and channel.
    ///
    /// - Parameters:
    ///   - job: The `Job` to persist.
    ///   - id: A unique id for the Job.
    ///   - channel: The name of the queue the `job` belongs on.
    /// - Throws: If the `job` is unable to be serialized to a String.
    public init<J: Job>(_ job: J, id: String = UUID().uuidString, channel: String) throws {
        self.id = id
        self.jobName = J.name
        self.channel = channel
        self.recoveryStrategy = job.recoveryStrategy
        self.attempts = 0
        self.backoffSeconds = job.retryBackoff.seconds
        self.backoffUntil = nil
        do {
            self.json = try job.jsonString()
        } catch {
            throw JobError("Error encoding Job of type `\(J.name)`: \(error)")
        }
    }
    
    /// Memberwise initializer.
    public init(id: JobID, json: JSONString, jobName: String, channel: String, recoveryStrategy: RecoveryStrategy, retryBackoff: TimeAmount, attempts: Int, backoffUntil: Date?) {
        self.id = id
        self.json = json
        self.jobName = jobName
        self.channel = channel
        self.recoveryStrategy = recoveryStrategy
        self.backoffSeconds = retryBackoff.seconds
        self.attempts = attempts
        self.backoffUntil = backoffUntil
    }
    
    mutating func updatePayload<J: Job>(_ job: J) throws {
        do {
            self.json = try job.jsonString()
        } catch {
            throw JobError("Error updating JobData payload to Job type `\(J.name)`: \(error)")
        }
    }
}

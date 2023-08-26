import NIO

public typealias JobID = String
public typealias JSONString = String

/// Represents a persisted Job, contains the serialized Job as well as some
/// additional info for `Queue`s.
public struct JobData: Codable, Equatable {
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
    public let backoff: TimeAmount
    /// Don't run this again until this time.
    public var backoffUntil: Date?
    /// The number of attempts this Job has been attempted.
    public var attempts: Int
    /// Can this job be retried.
    public var canRetry: Bool {
        switch recoveryStrategy {
        case .none:
            return false
        case .retry(let retries):
            return attempts <= retries
        }
    }
    
    /// Indicates if this job is currently in backoff, and should not
    /// be re-run yet.
    public var inBackoff: Bool {
        guard let date = backoffUntil else {
            return false
        }
        
        return date > Date()
    }

    /// The next date this job can be attempted. `nil` if the job can
    /// be retried immediately.
    public var nextRetryDate: Date? {
        backoff.seconds > 0
            ? Date().addingTimeInterval(TimeInterval(backoff.seconds))
            : nil
    }

    /// Create with a Job, id, and channel.
    ///
    /// - Parameters:
    ///   - job: The `Job` to persist.
    ///   - id: A unique id for the Job.
    ///   - channel: The name of the queue the `job` belongs on.
    /// - Throws: If the `job` is unable to be serialized to a String.
    public init<J: Job>(_ job: J, id: String = UUID().uuidString, channel: String) throws {
        // If the Job hasn't been registered, register it.
        if !JobDecoding.isRegistered(J.self) {
            JobDecoding.register(J.self)
        }
        
        self.id = id
        self.jobName = J.name
        self.channel = channel
        self.recoveryStrategy = job.recoveryStrategy
        self.attempts = 0
        self.backoff = job.retryBackoff
        self.backoffUntil = nil
        do {
            self.json = try job.jsonString()
        } catch {
            throw JobError("Error encoding Job of type `\(J.name)`: \(error)")
        }
    }
    
    /// Create a job data with the given data.
    ///
    /// - Parameters:
    ///   - id: A unique id for this job.
    ///   - json: The json string of the job.
    ///   - jobName: The name of this job.
    ///   - channel: The channel the job is supposed to run on.
    ///   - recoveryStrategy: How this job should handle failures.
    ///   - retryBackoff: How long a worker should wait to retry this
    ///     job after a failure.
    ///   - attempts: The number of times this job has been attempted
    ///     so far.
    ///   - backoffUntil: A date indicating the soonest this job can
    ///     be retried.
    public init(id: JobID, json: JSONString, jobName: String, channel: String, recoveryStrategy: RecoveryStrategy, retryBackoff: TimeAmount, attempts: Int, backoffUntil: Date?) {
        self.id = id
        self.json = json
        self.jobName = jobName
        self.channel = channel
        self.recoveryStrategy = recoveryStrategy
        self.backoff = retryBackoff
        self.attempts = attempts
        self.backoffUntil = backoffUntil
    }
}

extension TimeAmount: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(nanoseconds)
    }

    public init(from decoder: Decoder) throws {
        self = .nanoseconds(try decoder.singleValueContainer().decode(Int64.self))
    }
}

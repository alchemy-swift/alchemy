import NIO

/// Represents a persisted Job, contains the serialized Job as well as some
/// additional info for `Queue`s.
public struct JobData: Codable, Equatable {
    /// The unique id of this job, by default this is a UUID string.
    public let id: String
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
    /// The serialized Job this persists.
    public var payload: Data
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

    init(
        id: String = UUID().uuidString,
        payload: Data,
        jobName: String,
        channel: String,
        attempts: Int,
        recoveryStrategy: RecoveryStrategy,
        backoff: TimeAmount,
        backoffUntil: Date? = nil
    ) {
        self.id = id
        self.payload = payload
        self.jobName = jobName
        self.channel = channel
        self.recoveryStrategy = recoveryStrategy
        self.backoff = backoff
        self.backoffUntil = backoffUntil
        self.attempts = attempts
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

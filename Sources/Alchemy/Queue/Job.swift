import NIO

/// A task that can be persisted and queued for background processing.
public protocol Job {
    /// The name of this Job. Defaults to the type name.
    static var name: String { get }
    
    /// The recovery strategy for this job. Defaults to `.none`.
    var recoveryStrategy: RecoveryStrategy { get }
    
    /// The time that should be waited before retrying this job if it
    /// fails. Sub-second precision is ignored. Defaults to 0.
    var retryBackoff: TimeAmount { get }

    // MARK: Handling

    /// Creates this job from the given JobData.
    init(jobData: JobData) throws

    /// Enqueues this job on the given queue.
    func payload(for queue: Queue, channel: String) throws -> Data

    /// Run this Job.
    func run() async throws

    // MARK: Hooks

    /// Called when a job finishes, either successfully or with too
    /// many failed attempts.
    func finished(result: Result<Void, Error>)

    /// Called when a job fails, whether it can be retried or not.
    func failed(error: Error)
}

// By default, `Codable` Jobs will use JSON as their payload.
extension Job where Self: Codable {
    public init(jobData: JobData) throws {
        self = try JSONDecoder().decode(Self.self, from: jobData.payload)
    }

    public func payload(for queue: Queue, channel: String) throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// Default implementations.
extension Job {
    public static var name: String { Alchemy.name(of: Self.self) }
    public var recoveryStrategy: RecoveryStrategy { .none }
    public var retryBackoff: TimeAmount { .zero }
    
    public func finished(result: Result<Void, Error>) {
        switch result {
        case .success:
            Log.info("Job '\(Self.name)' succeeded.")
        case .failure(let error):
            Log.error("Job '\(Self.name)' failed with error: \(error).")
        }
    }
    
    public func failed(error: Error) {
        /* default to no-op */
    }

    /// Dispatch this Job on a queue.
    ///
    /// - Parameters:
    ///   - queue: The queue to dispatch on.
    ///   - channel: The name of the channel to dispatch on.
    public func dispatch(on queue: Queue = Q, channel: String = Queue.defaultChannel) async throws {
        try await queue.enqueue(self, channel: channel)
    }
}

public enum RecoveryStrategy: Equatable, Codable {
    /// The task will not be retried if it fails.
    case none
    /// The task will be retried after a failure, up to the specified amount.
    case retry(Int)

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case none, retry
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intValue = try container.decodeIfPresent(Int.self, forKey: .retry) {
            self = .retry(intValue)
        } else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encodeNil(forKey: .none)
        case .retry(let value):
            try container.encode(value, forKey: .retry)
        }
    }
}

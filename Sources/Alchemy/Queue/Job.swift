import NIO

/// A task that can be persisted and queued for background processing.
public protocol Job: Codable {
    /// The name of this Job. Defaults to the type name.
    static var name: String { get }
    
    /// The recovery strategy for this job. Defaults to `.none`.
    var recoveryStrategy: RecoveryStrategy { get }
    /// The time that should be waited before retrying this job if it
    /// fails. Sub-second precision is ignored. Defaults to 0.
    var retryBackoff: TimeAmount { get }
    
    /// Called when a job finishes, either successfully or with too
    /// many failed attempts.
    func finished(result: Result<Void, Error>)
    /// Run this Job.
    func run() async throws
}

// Default implementations.
extension Job {
    public static var name: String { Alchemy.name(of: Self.self) }
    public var recoveryStrategy: RecoveryStrategy { .none }
    public var retryBackoff: TimeAmount { .zero }
    
    public func finished(result: Result<Void, Error>) {
        switch result {
        case .success:
            Log.info("[Queue] Job '\(Self.name)' succeeded.")
        case .failure(let error):
            Log.error("[Queue] Job '\(Self.name)' failed with error: \(error).")
        }
    }
}

public enum RecoveryStrategy: Equatable {
    /// Removes task from the queue
    case none
    /// Retries the task a specified amount of times
    case retry(Int)
    
    /// The maximum number of retries allowed for this strategy.
    var maximumRetries: Int {
        switch self {
        case .none:
            return 0
        case .retry(let maxRetries):
            return maxRetries
        }
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

extension RecoveryStrategy: Codable {
    enum CodingKeys: String, CodingKey {
        case none, retry
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intValue = try container.decodeIfPresent(Int.self, forKey: .retry) {
            self = .retry(intValue)
        }
        else {
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

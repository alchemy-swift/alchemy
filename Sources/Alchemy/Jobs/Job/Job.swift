import NIO

public typealias JobID = String

public typealias PersistedJob = (id: JobID, job: Job)

public protocol Job {
    var recoveryStrategy: RecoveryStrategy { get }
    func run() -> EventLoopFuture<Void>
}

extension Job {

    public static var name: String {
        return String(describing: Self.self)
    }

    public var recoveryStrategy: RecoveryStrategy {
        return .none
    }
}

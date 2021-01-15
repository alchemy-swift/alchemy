import NIO

public typealias JobID = String

public protocol Job: Task {
    var recoveryStrategy: RecoveryStrategy { get }
    func failed(error: Error)
}

extension Job {
    var name: String { Self.name }
    public static var name: String {
        return String(describing: Self.self)
    }

    public var recoveryStrategy: RecoveryStrategy { .none }
}

public class PersistedJob: Codable {

    let id: JobID
    let name: String

    var job: Job? // figure this shit out

    var retries: Int = 0
    private var payload: [UInt8] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case retries
        case payload
    }

    init<T: Job>(id: JobID, payload: T) throws {
        self.id = id
        self.name = payload.name
        self.job = payload
        self.payload = try .init(JSONEncoder().encode(payload))
    }

    public func loadPayload<T: Job>(type: T.Type) throws {
        let decoded: T = try JSONDecoder().decode(type.self, from: .init(payload))
        self.job = decoded
    }

    func run() -> EventLoopFuture<Void> {
        self.job?.run() ?? EventLoopFuture.new()
    }

    func failed(error: Error) {
        self.job?.failed(error: error)
    }

    func shouldRetry(retries: Int) -> Bool {
        self.retries < retries
    }

    func retry() {
        self.retries += 1
    }
}

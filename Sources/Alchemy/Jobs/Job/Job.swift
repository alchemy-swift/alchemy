import NIO

public typealias JobID = String

public protocol Job: Task {
    associatedtype Payload

    func run(payload: Payload) -> EventLoopFuture<Void>
    func failed(error: Error)

    static func serializePayload(_ payload: Payload) throws -> Data
    static func parsePayload(bytes: Data) throws -> Payload
}

extension Job where Payload: Codable {
    public static func serializePayload(_ payload: Payload) throws -> Data {
        try JSONEncoder().encode(payload)
    }

    public static func parsePayload(bytes: Data) throws -> Payload {
        try JSONDecoder().decode(Payload.self, from: .init(bytes))
    }
}

extension Job {
    public func run(payload: Data) -> EventLoopFuture<Void> {
        do {
            return try self.run(payload: Self.parsePayload(bytes: payload))
        }
        catch let error {
            self.failed(error: error)
            return Services.eventLoop.makeFailedFuture(error)
        }
    }
}

public protocol PersistedJob: Codable {

    var name: String { get }
    var attempts: Int { get set }
    var payload: Data { get set }

    func run(job: Task) -> EventLoopFuture<Void>
    func shouldRetry(retries: Int) -> Bool
    mutating func retry()
}

extension PersistedJob {
    public func run(job: Task) -> EventLoopFuture<Void> {
        job.run(payload: self.payload)
    }

    public func shouldRetry(retries: Int) -> Bool {
        self.attempts < retries
    }

    public mutating func retry() {
        self.attempts += 1
    }
}

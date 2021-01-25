import NIO

public typealias JobID = String

public protocol AnyJob {
    func run(payload: Data) -> EventLoopFuture<Void>
    var recoveryStrategy: RecoveryStrategy { get }
}

extension AnyJob {
    var name: String { Self.name }
    public static var name: String {
        return String(describing: Self.self)
    }

    public var recoveryStrategy: RecoveryStrategy { .none }
}


public protocol Job: AnyJob {
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

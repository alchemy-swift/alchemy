import Foundation

/// Represents a type that may be the primary key of a database table. Out of
/// the box, `UUID`, `String` and `Int` are supported but you can easily
/// support your own by conforming to this protocol.
public protocol PrimaryKeyProtocol: Hashable, Codable, LosslessStringConvertible, SQLValueConvertible {
    /// Initialize this value from an `SQLValue`.
    init(value: SQLValue) throws
}

extension UUID: PrimaryKeyProtocol {
    public init(value: SQLValue) throws {
        self = try value.uuid()
    }
}

extension Int: PrimaryKeyProtocol {
    public init(value: SQLValue) throws {
        self = try value.int()
    }
}

extension String: PrimaryKeyProtocol {
    public init(value: SQLValue) throws {
        self = try value.string()
    }
}

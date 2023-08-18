import Foundation

/// Represents a type that may be a primary key in a database. Out of
/// the box `UUID`, `String` and `Int` are supported but you can
/// easily support your own by conforming to this protocol.
public protocol PrimaryKeyProtocol: Hashable, Codable, LosslessStringConvertible, SQLValueConvertible {
    /// Initialize this value from an `SQLValue`.
    ///
    /// - Throws: If there is an error decoding this type from the
    ///   given database value.
    /// - Parameter field: The field with which this type should be
    ///   initialzed from.
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

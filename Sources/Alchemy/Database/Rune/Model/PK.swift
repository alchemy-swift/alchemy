import Foundation

public final class PK<Identifier: PrimaryKey>: Codable, Hashable, Uniqueable, SQLValueConvertible, ModelProperty, CustomDebugStringConvertible {
    public var value: Identifier?
    fileprivate var storage: ModelStorage

    public var sqlValue: SQLValue {
        value.sqlValue
    }

    init(_ value: Identifier?) {
        self.value = value
        self.storage = .new
    }

    public var debugDescription: String {
        value.map { "\($0)" } ?? "null"
    }

    public func require() throws -> Identifier {
        guard let value else {
            throw DatabaseError("Object of type \(type(of: self)) had a nil id.")
        }

        return value
    }

    public func callAsFunction() -> Identifier {
        try! require()
    }

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        self.storage = .new
        self.storage.row = row.row
        self.value = try Identifier(value: row.require(key))
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        if let value {
            row.put(value, at: key)
        }
    }

    // MARK: Codable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }

    public init(from decoder: Decoder) throws {
        self.value = try decoder.singleValueContainer().decode(Identifier?.self)
        self.storage = .new
    }

    // MARK: Equatable

    public static func == (lhs: PK<Identifier>, rhs: PK<Identifier>) -> Bool {
        lhs.value == rhs.value
    }

    // MARK: Hashable

    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(value)
    }

    // MARK: Uniqueable

    public static func unique(id: Int) -> Self {
        Self(Identifier.unique(id: id))
    }

    public static var new: Self { .init(nil) }
    public static func new(_ value: Identifier) -> Self { .init(value) }
    public static func existing(_ value: Identifier) -> Self { .init(value) }
}

extension PK: ExpressibleByNilLiteral {
    public convenience init(nilLiteral: ()) {
        self.init(nil)
    }
}

extension PK<Int>: ExpressibleByIntegerLiteral {
    public convenience init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension PK<String>: ExpressibleByStringLiteral, ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral {
    public convenience init(unicodeScalarLiteral value: String) {
        self.init(value)
    }

    public convenience init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }

    public convenience init(stringLiteral value: String) {
        self.init(value)
    }
}

private final class ModelStorage {
    var row: SQLRow?
    var relationships: [String: Any]

    init() {
        self.relationships = [:]
        self.row = nil
    }

    static var new: ModelStorage {
        ModelStorage()
    }
}

extension Model {
    public var row: SQLRow? {
        id.storage.row
    }

    func cache<To>(_ value: To, at key: String) {
        id.storage.relationships[key] = value
    }

    func cached<To>(at key: String, _ type: To.Type = To.self) throws -> To? {
        guard let value = id.storage.relationships[key] else {
            return nil
        }

        guard let value = value as? To else {
            throw RuneError("Eager load cache type mismatch!")
        }

        return value
    }

    func cacheExists(_ key: String) -> Bool {
        id.storage.relationships[key] != nil
    }
}

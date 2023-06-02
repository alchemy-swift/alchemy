import Foundation

final class ModelStorage {
    var row: SQLRow
    var relationships: [Int: any RelationAllowed]

    init() {
        self.relationships = [:]
        self.row = SQLRow()
    }

    static var new: ModelStorage {
        ModelStorage()
    }
}

public final class PK<Identifier: PrimaryKey>: Codable, Hashable, SQLValueConvertible, ModelProperty, CustomDebugStringConvertible {
    public var value: Identifier?
    var storage: ModelStorage

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

    // MARK: ModelProperty

    public init(key: String, on row: SQLRowReader) throws {
        self.storage = .new
        self.storage.row = row.row
        self.value = try Identifier(value: row.require(key))
    }

    public func store(key: String, on row: inout SQLRowWriter) throws {
        row.put(value.sqlValue, at: key)
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

/// A protocol to which enums on `Model`s should conform to. The enum will be
/// modeled in the backing table by its raw value.
///
/// Usage:
/// ```swift
/// enum TaskPriority: Int, ModelEnum {
///     case low, medium, high
/// }
///
/// struct Todo: Model {
///     var id: PK<Int> = .new
///     let name: String
///     let isDone: Bool
///     let priority: TaskPriority // Stored as `Int` in the database.
/// }
/// ```
public protocol ModelEnum: ModelProperty, SQLValueConvertible {}

extension ModelEnum where Self: RawRepresentable, RawValue: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        guard let value = Self(rawValue: try RawValue(key: key, on: row)) else {
            throw RuneError("Error decoding \(name(of: Self.self)) from \(key)")
        }

        self = value
    }
    
    public func store(key: String, on row: SQLRowWriter) throws {
        try rawValue.store(key: key, on: row)
    }
}

extension ModelEnum where Self: RawRepresentable, RawValue: SQLValueConvertible {
    public var sqlValue: SQLValue {
        rawValue.sqlValue
    }
}

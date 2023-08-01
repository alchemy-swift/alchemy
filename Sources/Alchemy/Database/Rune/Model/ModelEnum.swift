/// A protocol to which enums on `Model`s should conform to. The enum
/// will be modeled in the backing table by it's raw value.
///
/// Usage:
/// ```swift
/// enum TaskPriority: Int, ModelEnum {
///     case low, medium, high
/// }
///
/// struct Todo: Model {
///     var id: Int?
///     let name: String
///     let isDone: Bool
///     let priority: TaskPriority // Stored as `Int` in the database.
/// }
/// ```
public protocol ModelEnum: Codable, ModelProperty {}

extension ModelEnum where Self: RawRepresentable, RawValue: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        guard let value = Self(rawValue: try RawValue(key: key, on: row)) else {
            throw RuneError("Error decoding \(name(of: Self.self)) from \(key)")
        }

        self = value
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        try rawValue.store(key: key, on: &row)
    }
}

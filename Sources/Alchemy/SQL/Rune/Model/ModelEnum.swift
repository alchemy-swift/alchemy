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
public protocol ModelEnum: ModelProperty, Codable, CaseIterable, AnyModelEnum {}

/// A type erased `ModelEnum`.
public protocol AnyModelEnum {
    /// A dummy value for this type. Defaults to `Self.allCases.first`.
    static var dummyValue: Self { get }
}

extension ModelEnum where Self: RawRepresentable, RawValue: ModelProperty {
    public init(key: String, on row: SQLRowReader) throws {
        self = try Self(rawValue: RawValue(key: key, on: row))
            .unwrap(or: DatabaseCodingError("Error decoding \(name(of: Self.self)) from \(key)"))
    }
    
    public func store(key: String, on row: inout SQLRowWriter) throws {
        try rawValue.store(key: key, on: &row)
    }
}

extension ModelEnum {
    public static var dummyValue: Self { Self.allCases.first! }
}

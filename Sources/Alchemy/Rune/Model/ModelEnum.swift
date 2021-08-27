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
public protocol ModelEnum: AnyModelEnum, CaseIterable {}
public protocol AnyModelEnum: Codable, Parameter {
    static var defaultCase: Self { get }
}

extension ModelEnum {
    public static var defaultCase: Self { Self.allCases.first! }
}

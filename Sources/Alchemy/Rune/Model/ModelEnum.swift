/// A protocol to which enums on `Model`s should conform to.
///
/// Usage:
/// ```
/// enum TaskPriority: Int, ModelEnum {
///     case low, medium, high
/// }
///
/// struct Todo: Model {
///     var id: Int?
///     var name: String
///     var isDone: Bool
///     var priority: TaskPriority // Usable for storing to and from an SQL database.
/// }
/// ```
typealias ModelEnum = Codable & Parameter

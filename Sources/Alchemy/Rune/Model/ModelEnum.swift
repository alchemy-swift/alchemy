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
///     var priority: TaskPriority
/// }
/// ```
protocol ModelEnum: Codable {
    /// A `DatabaseValue` representing the raw value of this enum.
    func databaseValue() -> DatabaseValue?
}

extension RawRepresentable where RawValue == String {
    // MARK: ModelEnum
    
    public func databaseValue() -> DatabaseValue? {
        .string(self.rawValue)
    }
}

extension RawRepresentable where RawValue == Int {
    // MARK: ModelEnum
    
    public func databaseValue() -> DatabaseValue? {
        .int(self.rawValue)
    }
}

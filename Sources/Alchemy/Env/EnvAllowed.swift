/// Protocol representing a type that can be created from a `String`.
public protocol StringInitializable {
    /// Create this type from a string.
    ///
    /// - Parameter value: The string to create this type from.
    init?(_ value: String)
}

extension String: StringInitializable {}
extension Int: StringInitializable {}
extension Double: StringInitializable {}
extension Bool: StringInitializable {}

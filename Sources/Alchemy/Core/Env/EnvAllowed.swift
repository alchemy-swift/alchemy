/// Protocol representing a type that can be created from a `String`
public protocol StringInitializable {
    init?(_ value: String)
}

extension String: StringInitializable {}
extension Int: StringInitializable {}
extension Double: StringInitializable {}
extension Bool: StringInitializable {}

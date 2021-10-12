import Foundation

public protocol Parameter {
    static func databaseValue(for value: Self?) -> DatabaseValue
}

extension Parameter {
    public var value: DatabaseValue { Self.databaseValue(for: self) }
}

extension DatabaseValue: Parameter {
    public static func databaseValue(for value: DatabaseValue?) -> DatabaseValue {
        value ?? .string(nil)
    }
}

extension String: Parameter {
    public static func databaseValue(for value: String?) -> DatabaseValue {
        .string(value)
    }
}

extension Int: Parameter {
    public static func databaseValue(for value: Int?) -> DatabaseValue {
        .int(value)
    }
}

extension Bool: Parameter {
    public static func databaseValue(for value: Bool?) -> DatabaseValue {
        .bool(value)
    }
}

extension Double: Parameter {
    public static func databaseValue(for value: Double?) -> DatabaseValue {
        .double(value)
    }
}

extension Date: Parameter {
    public static func databaseValue(for value: Date?) -> DatabaseValue {
        .date(value)
    }
}

extension UUID: Parameter {
    public static func databaseValue(for value: UUID?) -> DatabaseValue {
        .uuid(value)
    }
}

extension Optional: Parameter where Wrapped: Parameter {
    public static func databaseValue(for value: Optional<Wrapped>?) -> DatabaseValue {
        Wrapped.databaseValue(for: value ?? nil)
    }
}

extension RawRepresentable where RawValue: Parameter {
    public static func databaseValue(for value: Self?) -> DatabaseValue {
        RawValue.databaseValue(for: value?.rawValue)
    }
}

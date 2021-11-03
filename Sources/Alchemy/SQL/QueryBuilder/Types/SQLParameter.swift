import Foundation

public protocol SQLParameter {
    var value: DatabaseValue { get }
    
    // Replace with `static func value(value: Self?)` once 5.6 drops.
    static var nilValue: DatabaseValue { get }
}

extension DatabaseValue: SQLParameter {
    public var value: DatabaseValue { self }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension String: SQLParameter {
    public var value: DatabaseValue { .string(self) }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension Int: SQLParameter {
    public var value: DatabaseValue { .int(self) }
    public static var nilValue: DatabaseValue { .int(nil) }
}

extension Bool: SQLParameter {
    public var value: DatabaseValue { .bool(self) }
    public static var nilValue: DatabaseValue { .bool(nil) }
}

extension Double: SQLParameter {
    public var value: DatabaseValue { .double(self) }
    public static var nilValue: DatabaseValue { .double(nil) }
}

extension Date: SQLParameter {
    public var value: DatabaseValue { .date(self) }
    public static var nilValue: DatabaseValue { .date(nil) }
}

extension UUID: SQLParameter {
    public var value: DatabaseValue { .uuid(self) }
    public static var nilValue: DatabaseValue { .uuid(nil) }
}

extension Optional: SQLParameter where Wrapped: SQLParameter {
    public var value: DatabaseValue { self?.value ?? Wrapped.nilValue }
    public static var nilValue: DatabaseValue { Wrapped.nilValue }
}

extension RawRepresentable where RawValue: SQLParameter {
    public var value: DatabaseValue { self.rawValue.value }
    public static var nilValue: DatabaseValue { RawValue.nilValue }
}

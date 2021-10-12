import Foundation

public protocol Parameter {
    var value: DatabaseValue { get }
    
    // Replace with `static func value(value: Self?)` once 5.6 drops.
    static var nilValue: DatabaseValue { get }
}

extension DatabaseValue: Parameter {
    public var value: DatabaseValue { self }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension String: Parameter {
    public var value: DatabaseValue { .string(self) }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension Int: Parameter {
    public var value: DatabaseValue { .int(self) }
    public static var nilValue: DatabaseValue { .int(nil) }
}

extension Bool: Parameter {
    public var value: DatabaseValue { .bool(self) }
    public static var nilValue: DatabaseValue { .bool(nil) }
}

extension Double: Parameter {
    public var value: DatabaseValue { .double(self) }
    public static var nilValue: DatabaseValue { .double(nil) }
}

extension Date: Parameter {
    public var value: DatabaseValue { .date(self) }
    public static var nilValue: DatabaseValue { .date(nil) }
}

extension UUID: Parameter {
    public var value: DatabaseValue { .uuid(self) }
    public static var nilValue: DatabaseValue { .uuid(nil) }
}

extension Optional: Parameter where Wrapped: Parameter {
    public var value: DatabaseValue { self?.value ?? Wrapped.nilValue }
    public static var nilValue: DatabaseValue { Wrapped.nilValue }
}

extension RawRepresentable where RawValue: Parameter {
    public var value: DatabaseValue { self.rawValue.value }
    public static var nilValue: DatabaseValue { RawValue.nilValue }
}

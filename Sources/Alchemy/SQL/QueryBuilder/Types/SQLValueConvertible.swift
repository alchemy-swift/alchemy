import Foundation

public protocol SQLValueConvertible {
    var value: SQLValue { get }
    
    // Replace with `static func value(value: Self?)` once 5.6 drops.
    static var nilValue: SQLValue { get }
}

extension SQLValue: SQLValueConvertible {
    public var value: SQLValue { self }
    public static var nilValue: SQLValue { .string(nil) }
}

extension String: SQLValueConvertible {
    public var value: SQLValue { .string(self) }
    public static var nilValue: SQLValue { .string(nil) }
}

extension Int: SQLValueConvertible {
    public var value: SQLValue { .int(self) }
    public static var nilValue: SQLValue { .int(nil) }
}

extension Bool: SQLValueConvertible {
    public var value: SQLValue { .bool(self) }
    public static var nilValue: SQLValue { .bool(nil) }
}

extension Double: SQLValueConvertible {
    public var value: SQLValue { .double(self) }
    public static var nilValue: SQLValue { .double(nil) }
}

extension Date: SQLValueConvertible {
    public var value: SQLValue { .date(self) }
    public static var nilValue: SQLValue { .date(nil) }
}

extension UUID: SQLValueConvertible {
    public var value: SQLValue { .uuid(self) }
    public static var nilValue: SQLValue { .uuid(nil) }
}

extension Optional: SQLValueConvertible where Wrapped: SQLValueConvertible {
    public var value: SQLValue { self?.value ?? Wrapped.nilValue }
    public static var nilValue: SQLValue { Wrapped.nilValue }
}

extension RawRepresentable where RawValue: SQLValueConvertible {
    public var value: SQLValue { self.rawValue.value }
    public static var nilValue: SQLValue { RawValue.nilValue }
}

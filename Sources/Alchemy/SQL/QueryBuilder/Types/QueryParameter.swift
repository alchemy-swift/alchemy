import Foundation

public protocol QueryParameter {
    var value: DatabaseValue { get }
    
    // Replace with `static func value(value: Self?)` once 5.6 drops.
    static var nilValue: DatabaseValue { get }
}

extension DatabaseValue: QueryParameter {
    public var value: DatabaseValue { self }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension String: QueryParameter {
    public var value: DatabaseValue { .string(self) }
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension Int: QueryParameter {
    public var value: DatabaseValue { .int(self) }
    public static var nilValue: DatabaseValue { .int(nil) }
}

extension Bool: QueryParameter {
    public var value: DatabaseValue { .bool(self) }
    public static var nilValue: DatabaseValue { .bool(nil) }
}

extension Double: QueryParameter {
    public var value: DatabaseValue { .double(self) }
    public static var nilValue: DatabaseValue { .double(nil) }
}

extension Date: QueryParameter {
    public var value: DatabaseValue { .date(self) }
    public static var nilValue: DatabaseValue { .date(nil) }
}

extension UUID: QueryParameter {
    public var value: DatabaseValue { .uuid(self) }
    public static var nilValue: DatabaseValue { .uuid(nil) }
}

extension Optional: QueryParameter where Wrapped: QueryParameter {
    public var value: DatabaseValue { self?.value ?? Wrapped.nilValue }
    public static var nilValue: DatabaseValue { Wrapped.nilValue }
}

extension RawRepresentable where RawValue: QueryParameter {
    public var value: DatabaseValue { self.rawValue.value }
    public static var nilValue: DatabaseValue { RawValue.nilValue }
}

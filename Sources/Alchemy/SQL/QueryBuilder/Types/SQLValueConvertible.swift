import Foundation

public protocol SQLValueConvertible {
    var value: SQLValue { get }
}

extension SQLValueConvertible {
    public static var nilValue: SQLValue { .null }
}

extension SQLValue: SQLValueConvertible {
    public var value: SQLValue { self }
}

extension String: SQLValueConvertible {
    public var value: SQLValue { .string(self) }
}

extension Int: SQLValueConvertible {
    public var value: SQLValue { .int(self) }
}

extension Bool: SQLValueConvertible {
    public var value: SQLValue { .bool(self) }
}

extension Double: SQLValueConvertible {
    public var value: SQLValue { .double(self) }
}

extension Date: SQLValueConvertible {
    public var value: SQLValue { .date(self) }
}

extension UUID: SQLValueConvertible {
    public var value: SQLValue { .uuid(self) }
}

extension Optional: SQLValueConvertible where Wrapped: SQLValueConvertible {
    public var value: SQLValue { self?.value ?? Wrapped.nilValue }
}

extension RawRepresentable where RawValue: SQLValueConvertible {
    public var value: SQLValue { self.rawValue.value }
}

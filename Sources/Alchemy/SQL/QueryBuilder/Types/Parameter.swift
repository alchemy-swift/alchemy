import Foundation

public protocol Parameter {
    var value: DatabaseValue { get }
}

extension DatabaseValue: Parameter {
    public var value: DatabaseValue { self }
}

extension String: Parameter {
    public var value: DatabaseValue { .string(self) }
}

extension Int: Parameter {
    public var value: DatabaseValue { .int(self) }
}

extension Bool: Parameter {
    public var value: DatabaseValue { .bool(self) }
}

extension Double: Parameter {
    public var value: DatabaseValue { .double(self) }
}

extension Date: Parameter {
    public var value: DatabaseValue { .date(self) }
}

extension UUID: Parameter {
    public var value: DatabaseValue { .uuid(self) }
}

extension Optional: Parameter where Wrapped: Parameter {
    public var value: DatabaseValue { self?.value ?? .string(nil) }
}

extension RawRepresentable where RawValue: Parameter {
    public var value: DatabaseValue { self.rawValue.value }
}

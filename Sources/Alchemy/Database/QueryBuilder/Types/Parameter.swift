import Foundation

public protocol Parameter {
    var value: DatabaseValue { get }
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

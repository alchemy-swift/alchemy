import Foundation

public protocol Parameter {
    var value: DatabaseValue { get }
}

extension Parameter {
    /// A null value... pretty sure it won't matter what the type is? If it does can move this into each
    /// extension.
    public static var null: Parameter { DatabaseValue.string(nil) }
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

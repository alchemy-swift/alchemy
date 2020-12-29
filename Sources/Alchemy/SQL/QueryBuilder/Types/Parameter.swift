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
    // MARK: Parameter
    
    public var value: DatabaseValue { self }
}

extension String: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .string(self) }
}

extension Int: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .int(self) }
}

extension Bool: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .bool(self) }
}

extension Double: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .double(self) }
}

extension Date: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .date(self) }
}

extension UUID: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { .uuid(self) }
}

extension Optional: Parameter where Wrapped: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { self?.value ?? .string(nil) }
}

extension RawRepresentable where RawValue: Parameter {
    // MARK: Parameter
    
    public var value: DatabaseValue { self.rawValue.value }
}

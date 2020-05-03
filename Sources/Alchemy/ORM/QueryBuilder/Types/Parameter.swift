import Foundation

public protocol Parameter: CustomStringConvertible {
    var value: CustomStringConvertible { get }
}

extension Parameter {
    var description: String { value.description }
}

extension String: Parameter {
    public var value: CustomStringConvertible { self }
}

extension Int: Parameter {
    public var value: CustomStringConvertible { String(self) }
}

extension Bool: Parameter {
    public var value: CustomStringConvertible { String(self) }
}

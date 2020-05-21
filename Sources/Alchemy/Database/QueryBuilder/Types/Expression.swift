import Foundation

struct Expression: Parameter {
    private var _value: String
    public var value: DatabaseValue { .string(_value) }

    init(_ value: String) {
        self._value = value
    }
}

extension Expression: CustomStringConvertible {
    var description: String { return self._value }
}

import Foundation

struct Expression: SQLValueConvertible {
    private var _value: String
    
    var value: SQLValue { .string(_value) }
    
    init(_ value: String) {
        self._value = value
    }
}

extension Expression: CustomStringConvertible {
    var description: String { _value }
}

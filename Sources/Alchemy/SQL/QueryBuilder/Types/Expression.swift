import Foundation

struct Expression: SQLParameter {
    private var _value: String
    
    var value: DatabaseValue { .string(_value) }
    
    init(_ value: String) {
        self._value = value
    }
    
    public static var nilValue: DatabaseValue { .string(nil) }
}

extension Expression: CustomStringConvertible {
    var description: String { _value }
}

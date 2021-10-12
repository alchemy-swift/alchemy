import Foundation

struct Expression: Parameter {
    private var _value: String
    
    init(_ value: String) {
        self._value = value
    }
    
    static func databaseValue(for value: Expression?) -> DatabaseValue {
        .string(value?._value)
    }
}

extension Expression: CustomStringConvertible {
    var description: String { return self._value }
}

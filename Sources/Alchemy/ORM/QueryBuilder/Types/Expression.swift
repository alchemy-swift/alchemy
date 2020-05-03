import Foundation

struct Expression: Parameter {
    let value: CustomStringConvertible

    init(_ value: CustomStringConvertible) {
        self.value = value
    }
}

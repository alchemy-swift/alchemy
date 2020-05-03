import Foundation

protocol Clause {
    func toString() -> String
}

struct Expression: Clause {
    let value: CustomStringConvertible

    func toString() -> String {
        return value.description
    }
}

extension String: Clause {
    func toString() -> String { return self }
}

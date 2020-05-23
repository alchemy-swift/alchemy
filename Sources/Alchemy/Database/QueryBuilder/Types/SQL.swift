import Foundation

public struct SQL {
    let query: String
    let bindings: [DatabaseValue]

    public init(_ query: String = "", bindings: [DatabaseValue] = []) {
        self.query = query
        self.bindings = bindings
    }

    public init(_ query: String, binding: DatabaseValue) {
        self.init(query, bindings: [binding])
    }

    @discardableResult
    func bind(_ bindings: inout [DatabaseValue]) -> SQL {
        bindings.append(contentsOf: self.bindings)
        return self
    }

    @discardableResult
    func bind(queries: inout [String], bindings: inout [DatabaseValue]) -> SQL {
        queries.append(self.query)
        bindings.append(contentsOf: self.bindings)
        return self
    }
}

public typealias Raw = SQL

import Foundation

public struct SQL {
    let query: String
    let bindings: [DatabaseValue]

    init(_ query: String = "", bindings: [DatabaseValue] = []) {
        self.query = query
        self.bindings = bindings
    }

    init(_ query: String, binding: DatabaseValue) {
        self.init(query, bindings: [binding])
    }

    func bind(_ bindings: inout [DatabaseValue]) -> SQL {
        bindings.append(contentsOf: self.bindings)
        return self
    }

    func bind(queries: inout [String], bindings: inout [DatabaseValue]) -> SQL {
        queries.append(self.query)
        bindings.append(contentsOf: self.bindings)
        return self
    }
}

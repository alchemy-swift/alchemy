import Foundation

public struct SQL {
    var query: String
    let bindings: [SQLValue]

    public init(_ query: String = "", bindings: [SQLValue] = []) {
        self.query = query
        self.bindings = bindings
    }

    public init(_ query: String, binding: SQLValue) {
        self.init(query, bindings: [binding])
    }

    @discardableResult
    func bind(_ bindings: inout [SQLValue]) -> SQL {
        bindings.append(contentsOf: self.bindings)
        return self
    }

    @discardableResult
    func bind(queries: inout [String], bindings: inout [SQLValue]) -> SQL {
        queries.append(self.query)
        bindings.append(contentsOf: self.bindings)
        return self
    }
}

extension SQL: Equatable {
    public static func == (lhs: SQL, rhs: SQL) -> Bool {
        lhs.query == rhs.query && lhs.bindings == rhs.bindings
    }
}

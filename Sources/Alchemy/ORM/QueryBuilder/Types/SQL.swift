import Foundation

public struct SQL {
    let query: String
    let bindings: [Parameter]

    init(_ query: String = "", bindings: [Parameter] = []) {
        self.query = query
        self.bindings = bindings
    }

    init(_ query: String, binding: Parameter) {
        self.init(query, bindings: [binding])
    }

    func bind(_ bindings: inout [Parameter]) -> SQL {
        bindings.append(contentsOf: self.bindings)
        return self
    }

    func bind(queries: inout [String], bindings: inout [Parameter]) -> SQL {
        queries.append(self.query)
        bindings.append(contentsOf: self.bindings)
        return self
    }
}

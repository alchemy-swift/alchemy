import Foundation

protocol Sequelizable {
    func toSQL() -> SQL
}

func groupSQL(values: [Sequelizable]) -> ([String], [Parameter]) {
    return values.reduce(([String](), [Parameter]())) {
        var parts = $0
        let sql = $1.toSQL()
        parts.0.append(sql.query)
        parts.1.append(contentsOf: sql.bindings)
        return parts
    }
}

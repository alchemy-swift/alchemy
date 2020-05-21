import Foundation

class QueryHelpers {
    static func removeLeadingBoolean(_ value: String) -> String {
        if value.hasPrefix("and ") {
            return String(value.dropFirst(4))
        }
        else if value.hasPrefix("or ") {
            return String(value.dropFirst(3))
        }
        return value
    }

    static func groupSQL(values: [Sequelizable]) -> ([String], [DatabaseValue]) {
        return values.reduce(([String](), [DatabaseValue]())) {
            var parts = $0
            let sql = $1.toSQL()
            parts.0.append(sql.query)
            parts.1.append(contentsOf: sql.bindings)
            return parts
        }
    }
}

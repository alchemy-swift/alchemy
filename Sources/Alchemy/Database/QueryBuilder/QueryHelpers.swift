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
        self.groupSQL(values: values.map { $0.toSQL() })
    }

    static func groupSQL(values: [SQL]) -> ([String], [DatabaseValue]) {
        return values.reduce(([String](), [DatabaseValue]())) {
            var parts = $0
            parts.0.append($1.query)
            parts.1.append(contentsOf: $1.bindings)
            return parts
        }
    }
}

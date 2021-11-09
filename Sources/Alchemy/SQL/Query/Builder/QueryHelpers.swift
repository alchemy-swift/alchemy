import Foundation

enum QueryHelpers {
    static func removeLeadingBoolean(_ value: String) -> String {
        if value.hasPrefix("and ") {
            return String(value.dropFirst(4))
        }
        else if value.hasPrefix("or ") {
            return String(value.dropFirst(3))
        }
        return value
    }

    static func groupSQL(values: [SQLConvertible]) -> ([String], [SQLValue]) {
        self.groupSQL(values: values.map(\.sql))
    }

    static func groupSQL(values: [SQL?]) -> ([String], [SQLValue]) {
        return values.reduce(([String](), [SQLValue]())) {
            var parts = $0
            guard let sql = $1 else { return parts }
            parts.0.append(sql.query)
            parts.1.append(contentsOf: sql.bindings)
            return parts
        }
    }
}

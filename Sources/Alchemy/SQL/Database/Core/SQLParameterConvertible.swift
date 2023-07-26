import Foundation

// TODO: May be able to change this to SQLConvertible. Would still infer string I think? Maybe try it.
// TODO: Consider naming around binds, parameters, values, etc. What goes where?
public protocol SQLParameterConvertible {
    var sqlParameter: SQLParameter { get }
}

extension SQLParameterConvertible where Self == SQLParameter {
    public static func raw(_ sql: SQL) -> Self {
        .expression(sql)
    }

    public static var null: Self {
        .value(.null)
    }

    public static var now: Self {
        .value(.date(Date()))
    }
}

extension SQLParameterConvertible {
    /// A string appropriate for representing this value in a non-parameterized
    /// query.
    public var rawSQLString: String {
        switch sqlParameter {
        case .expression(let sql):
            return sql.rawSQLString
        case .value(let value):
            switch value {
            case .int(let value):
                return "\(value)"
            case .double(let value):
                return "\(value)"
            case .bool(let value):
                return "\(value)"
            case .string(let value):
                // ' -> '' escapes in MySQL, Postgres & SQLite
                return "'\(value.replacingOccurrences(of: "'", with: "''"))'"
            case .date(let value):
                return "'\(value)'"
            case .json(let value):
                let rawString = String(data: value, encoding: .utf8) ?? ""
                return "'\(rawString)'"
            case .data(let value):
                let rawString = String(data: value, encoding: .utf8) ?? "<bytes>"
                return "'\(rawString)'"
            case .uuid(let value):
                return "'\(value.uuidString)'"
            case .null:
                return "NULL"
            }
        }
    }
}

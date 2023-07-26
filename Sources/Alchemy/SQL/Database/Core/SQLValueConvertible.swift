import Foundation

/*
 Could have SQL convertible, but then if the user put a "HELLO" string there,
 it wouldn't know if it's `SQL` or `String`. It should be interpreted as
 String, with an option to explicitly specify raw SQL.

 Therefore, this shouldn't even accept SQL, since the ExpressibleByStringLiteral
 conformance will make it impossible to distringuish if a String literal is
 SQL or String.

 Any way around that?
 */

public protocol SQLValueConvertible: SQLParameterConvertible {
    var sqlValue: SQLValue { get }
}

extension SQLValueConvertible {
    public var sqlParameter: SQLParameter { .value(sqlValue) }
}

public enum SQLParameter: Equatable, Hashable, SQLParameterConvertible {
    /// A raw SQL expression such as "NOW()".
    case expression(SQL)
    /// An value that can be bound to a query parameter, such as `"Josh"` or `26`.
    case value(SQLValue)

    public var sqlParameter: SQLParameter { self }

    public var rawSQLString: String {
        switch self {
        case .expression(let sql):
            return sql.rawSQLString
        case .value(let value):
            return value.rawSQLString
        }
    }
}

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

extension SQLValue: SQLValueConvertible {
    public var sqlValue: SQLValue { self }
}

extension String: SQLValueConvertible {
    public var sqlValue: SQLValue { .string(self) }
}

extension FixedWidthInteger {
    public var sqlValue: SQLValue { .int(Int(self)) }
}

extension Int: SQLValueConvertible {}
extension Int8: SQLValueConvertible {}
extension Int16: SQLValueConvertible {}
extension Int32: SQLValueConvertible {}
extension Int64: SQLValueConvertible {}
extension UInt: SQLValueConvertible {}
extension UInt8: SQLValueConvertible {}
extension UInt16: SQLValueConvertible {}
extension UInt32: SQLValueConvertible {}
extension UInt64: SQLValueConvertible {}

extension Bool: SQLValueConvertible {
    public var sqlValue: SQLValue { .bool(self) }
}

extension Double: SQLValueConvertible {
    public var sqlValue: SQLValue { .double(self) }
}

extension Float: SQLValueConvertible {
    public var sqlValue: SQLValue { .double(Double(self)) }
}

extension Date: SQLValueConvertible {
    public var sqlValue: SQLValue { .date(self) }
}

extension UUID: SQLValueConvertible {
    public var sqlValue: SQLValue { .uuid(self) }
}

extension Optional: SQLValueConvertible, SQLParameterConvertible where Wrapped: SQLValueConvertible {
    public var sqlValue: SQLValue { self?.sqlValue ?? .null }
}

extension RawRepresentable where RawValue: SQLValueConvertible {
    public var sqlValue: SQLParameterConvertible { rawValue.sqlValue }
}

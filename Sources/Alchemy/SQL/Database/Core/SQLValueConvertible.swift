import Foundation

protocol SQLParameterConvertible {
    var sqlParameter: SQLParameter { get }
}

enum SQLParameter {
    case expression(SQL)
    case value(SQLValue)
}

public protocol SQLValueConvertible {
    var sqlValue: SQLValue { get }
}

extension SQLValueConvertible {
    /// A string appropriate for representing this value in a non-parameterized
    /// query.
    public var rawSQLString: String {
        switch sqlValue {
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
        case .raw(let value):
            return value.rawSQLString
        case .null:
            return "NULL"
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

extension Optional: SQLValueConvertible where Wrapped: SQLValueConvertible {
    public var sqlValue: SQLValue { self?.sqlValue ?? .null }
}

extension RawRepresentable where RawValue: SQLValueConvertible {
    public var sqlValue: SQLValue { rawValue.sqlValue }
}

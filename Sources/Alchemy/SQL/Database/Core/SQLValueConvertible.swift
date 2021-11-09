import Foundation

public protocol SQLValueConvertible: SQLConvertible {
    var value: SQLValue { get }
}

extension SQLValueConvertible {
    public var sql: SQL {
        (self as? SQL) ?? SQL(sqlValueLiteral)
    }
    
    /// A string appropriate for representing this value in a non-parameterized
    /// query.
    public var sqlValueLiteral: String {
        switch self.value {
        case .int(let value):
            return "\(value)"
        case .double(let value):
            return "\(value)"
        case .bool(let value):
            return "\(value)"
        case .string(let value):
            // ' -> '' is escape for MySQL & Postgres... not sure if this will break elsewhere.
            return "'\(value.replacingOccurrences(of: "'", with: "''"))'"
        case .date(let value):
            return "'\(value)'"
        case .json(let value):
            let rawString = String(data: value, encoding: .utf8) ?? ""
            return "'\(rawString)'"
        case .uuid(let value):
            return "'\(value.uuidString)'"
        case .null:
            return "NULL"
        }
    }
}

extension SQLValue: SQLValueConvertible {
    public var value: SQLValue { self }
}

extension String: SQLValueConvertible {
    public var value: SQLValue { .string(self) }
}

extension Int: SQLValueConvertible {
    public var value: SQLValue { .int(self) }
}

extension Bool: SQLValueConvertible {
    public var value: SQLValue { .bool(self) }
}

extension Double: SQLValueConvertible {
    public var value: SQLValue { .double(self) }
}

extension Date: SQLValueConvertible {
    public var value: SQLValue { .date(self) }
}

extension UUID: SQLValueConvertible {
    public var value: SQLValue { .uuid(self) }
}

extension Optional: SQLConvertible where Wrapped: SQLValueConvertible {}

extension Optional: SQLValueConvertible where Wrapped: SQLValueConvertible {
    public var value: SQLValue { self?.value ?? .null }
}

extension RawRepresentable where RawValue: SQLValueConvertible {
    public var value: SQLValue { rawValue.value }
}

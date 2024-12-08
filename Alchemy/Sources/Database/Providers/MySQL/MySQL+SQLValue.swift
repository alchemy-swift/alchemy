import MySQLNIO

extension MySQLData: SQLValueConvertible {
    /// Initialize from an `SQLValue`.
    init(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            self = MySQLData(bool: value)
        case .date(let value):
            self = MySQLData(date: value)
        case .double(let value):
            self = MySQLData(double: value)
        case .int(let value):
            self = MySQLData(int: value)
        case .json(let bytes):
            self = MySQLData(type: .json, format: .text, buffer: bytes)
        case .string(let value):
            self = MySQLData(string: value)
        case .uuid(let value):
            self = MySQLData(string: value.uuidString)
        case .bytes(let bytes):
            self = MySQLData(type: .blob, format: .binary, buffer: bytes)
        case .null:
            self = .null
        }
    }

    public var sqlValue: SQLValue {
        switch type {
        case .int24, .short, .long, .longlong:
            return int.map { .int($0) } ?? .null
        case .tiny:
            return bool.map { .bool($0) } ?? .null
        case .varchar, .string, .varString, .blob, .tinyBlob, .mediumBlob, .longBlob:
            return string.map { .string($0) } ?? .null
        case .date, .timestamp, .timestamp2, .datetime, .datetime2:
            return time?.date.map { .date($0) } ?? .null
        case .float, .decimal, .double:
            return double.map { .double($0) } ?? .null
        case .json:
            return buffer.map { .json($0) } ?? .null
        case .null:
            return .null
        default:
            return buffer.map { .bytes($0) } ?? .null
        }
    }
}

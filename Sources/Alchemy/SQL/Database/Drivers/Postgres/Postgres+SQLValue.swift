import PostgresNIO

extension PostgresData {
    /// Initialize from an Alchemy `SQLValue`.
    init(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            self = PostgresData(bool: value)
        case .date(let value):
            self = PostgresData(date: value)
        case .double(let value):
            self = PostgresData(double: value)
        case .int(let value):
            self = PostgresData(int: value)
        case .json(let bytes):
            self = PostgresData(type: .json, formatCode: .binary, value: bytes)
        case .string(let value):
            self = PostgresData(string: value)
        case .uuid(let value):
            self = PostgresData(uuid: value)
        case .bytes(let bytes):
            self = PostgresData(type: .bytea, formatCode: .binary, value: bytes)
        case .null:
            self = .null
        }
    }
}

extension PostgresCell: SQLValueConvertible {
    public var sqlValue: SQLValue {
        switch dataType {
        case .int2, .int4, .int8:
            return (try? .int(decode(Int.self))) ?? .null
        case .bool:
            return (try? .bool(decode(Bool.self))) ?? .null
        case .varchar, .text:
            return (try? .string(decode(String.self))) ?? .null
        case .date, .timestamptz, .timestamp:
            return (try? .date(decode(Date.self))) ?? .null
        case .float4, .float8:
            return (try? .double(decode(Double.self))) ?? .null
        case .uuid:
            return (try? .uuid(decode(UUID.self))) ?? .null
        case .json, .jsonb:
            return bytes.map { .json($0) } ?? .null
        case .null:
            return .null
        default:
            return bytes.map { .bytes($0) } ?? .null
        }
    }
}

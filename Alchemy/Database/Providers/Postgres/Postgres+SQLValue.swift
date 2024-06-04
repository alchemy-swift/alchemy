import PostgresNIO

extension PostgresBindings {
    private struct _JSON: PostgresNonThrowingEncodable {
        static var psqlType: PostgresDataType = .json
        static var psqlFormat: PostgresFormat = .binary

        let bytes: ByteBuffer

        func encode<JSONEncoder: PostgresJSONEncoder>(into byteBuffer: inout ByteBuffer, context: PostgresEncodingContext<JSONEncoder>) {
            var bytes = bytes
            byteBuffer.writeBuffer(&bytes)
        }
    }

    private struct _Bytes: PostgresNonThrowingEncodable {
        static var psqlType: PostgresDataType = .bytea
        static var psqlFormat: PostgresFormat = .binary

        let bytes: ByteBuffer

        func encode<JSONEncoder: PostgresJSONEncoder>(into byteBuffer: inout ByteBuffer, context: PostgresEncodingContext<JSONEncoder>) {
            var bytes = bytes
            byteBuffer.writeBuffer(&bytes)
        }
    }

    mutating func append(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            append(value, context: .default)
        case .date(let value):
            append(value, context: .default)
        case .double(let value):
            append(value, context: .default)
        case .int(let value):
            append(value, context: .default)
        case .json(let bytes):
            append(_JSON(bytes: bytes), context: .default)
        case .string(let value):
            append(value, context: .default)
        case .uuid(let value):
            append(value, context: .default)
        case .bytes(let bytes):
            append(_Bytes(bytes: bytes), context: .default)
        case .null:
            appendNull()
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
        case .varchar, .text, .name:
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

import Foundation
import PostgresNIO

extension PostgresData {
    func toDatabaseField(from column: String) throws -> DatabaseField {
        switch self.type {
        case .int2, .int4, .int8:
            return DatabaseField(
                column: column,
                value: .int(try self.int.unwrap(or: PostgresError.unwrapError("int", column: column)))
            )
        case .bool:
            return DatabaseField(
                column: column,
                value: .bool(try self.bool.unwrap(or: PostgresError.unwrapError("bool", column: column)))
            )
        case .varchar, .text:
            return DatabaseField(
                column: column,
                value: .string(try self.string.unwrap(or: PostgresError.unwrapError("string", column: column)))
            )
        case .date, .time, .timestamp, .timetz, .timestamptz:
            return DatabaseField(
                column: column,
                value: .date(try self.date.unwrap(or: PostgresError.unwrapError("date", column: column)))
            )
        case .float4, .float8:
            return DatabaseField(
                column: column,
                value: .double(try self.double.unwrap(or: PostgresError.unwrapError("double", column: column)))
            )
        case .uuid:
            // The `PostgresNIO` `UUID` parser doesn't seem to work properly `self.uuid` returns nil.
            let uuid = self.string.flatMap { UUID(uuidString: $0) }
            return DatabaseField(
                column: column,
                value: .uuid(try uuid.unwrap(or: PostgresError.unwrapError("uuid", column: column)))
            )
        case .json, .jsonb:
            return DatabaseField(
                column: column,
                value: .json(try self.json.unwrap(or: PostgresError.unwrapError("json", column: column)))
            )
        default:
            throw PostgresError(message: "Couldn't parse a `\(self.type)` from column '\(column)'. That Postgres datatype isn't supported, yet.")
        }
    }
}

extension DatabaseField {
    func toPostgresData() -> PostgresData {
        switch self.value {
        case .bool(let value):
            return PostgresData(bool: value)
        case .date(let value):
            return PostgresData(date: value)
        case .double(let value):
            return PostgresData(double: value)
        case .int(let value):
            return PostgresData(int: value)
        case .json(let value):
            return PostgresData(json: value)
        case .string(let value):
            return PostgresData(string: value)
        case .uuid(let value):
            return PostgresData(uuid: value)
        case .array(_):
            /// TODO: Support arrays
            return PostgresData(array: [], elementType: .bool)
        }
    }
}

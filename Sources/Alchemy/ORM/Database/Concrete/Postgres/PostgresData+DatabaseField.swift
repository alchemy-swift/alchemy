import Foundation
import PostgresNIO

extension PostgresData {
    private static let postgresDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    private static let postgresTimestampzFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSX"
        return dateFormatter
    }()
    
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
        case .date:
            let string = try self.string.unwrap(or: PostgresError.unwrapError("date", column: column))
            let date = try PostgresData.postgresDateFormatter.date(from: string)
                .unwrap(or: PostgresError.unwrapError("date", column: column))
            return DatabaseField(
                column: column,
                value: .date(date)
            )
        case .timestamptz:
            let string = try self.string.unwrap(or: PostgresError.unwrapError("date", column: column))
            let date = try PostgresData.postgresTimestampzFormatter.date(from: string)
                .unwrap(or: PostgresError.unwrapError("date", column: column))
            return DatabaseField(
                column: column,
                value: .date(date)
            )
        case .time, .timestamp, .timetz:
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
            guard let value = value else { return .null }
            return PostgresData(bool: value)
        case .date(let value):
            guard let value = value else { return .null }
            return PostgresData(date: value)
        case .double(let value):
            guard let value = value else { return .null }
            return PostgresData(double: value)
        case .int(let value):
            guard let value = value else { return .null }
            return PostgresData(int: value)
        case .json(let value):
            guard let value = value else { return .null }
            return PostgresData(json: value)
        case .string(let value):
            guard let value = value else { return .null }
            return PostgresData(string: value)
        case .uuid(let value):
            guard let value = value else { return .null }
            return PostgresData(uuid: value)
        case .arrayString(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayInt(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayDouble(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayBool(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayDate(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayJSON(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        case .arrayUUID(let value):
            guard let value = value else { return .null }
            return PostgresData(array: value)
        }
    }
}

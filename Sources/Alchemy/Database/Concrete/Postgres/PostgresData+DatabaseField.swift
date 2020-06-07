import Foundation
import PostgresNIO

extension PostgresData {
    func toDatabaseField(from column: String) throws -> DatabaseField {
        // Ensures that if value is nil, it's because the database column is actually nil and not because
        // we are attempting to pull out the wrong type.
        func validateNil<T>(_ value: T?) throws -> T? {
            if self.value == nil {
                return nil
            } else if value == nil {
                let errorMessage = "Unable to unwrap expected type `\(name(of: T.self))` from column "
                + "'\(column)'."
                throw PostgresError(errorMessage)
            } else {
                return value
            }
        }
        
        switch self.type {
        case .int2, .int4, .int8:
            return DatabaseField(column: column, value: .int(try validateNil(self.int)))
        case .bool:
            return DatabaseField(column: column, value: .bool(try validateNil(self.bool)))
        case .varchar, .text:
            return DatabaseField(column: column, value: .string(try validateNil(self.string)))
        case .date:
            return DatabaseField(column: column, value: .date(try validateNil(self.date)))
        case .timestamptz:
            return DatabaseField(column: column, value: .date(try validateNil(self.date)))
        case .time, .timestamp, .timetz:
            fatalError("Need to do these.")
        case .float4, .float8:
            return DatabaseField(column: column, value: .double(try validateNil(self.double)))
        case .uuid:
            // The `PostgresNIO` `UUID` parser doesn't seem to work properly `self.uuid` returns nil.
            let string = try validateNil(self.string)
            let uuid = try string.map { string -> UUID in
                guard let uuid = UUID(uuidString: string) else {
                    throw PostgresError("Invalid UUID '\(string)' at column '\(column)'")
                }
                
                return uuid
            }
            return DatabaseField(column: column, value: .uuid(uuid))
        case .json, .jsonb:
            return DatabaseField(column: column, value: .json(try validateNil(self.json)))
        case .int2Array, .int4Array, .int8Array:
            return DatabaseField(column: column, value: .arrayInt(try validateNil(self.array(of: Int.self))))
        case .float4Array, .float8Array:
            return DatabaseField(column: column,
                                 value: .arrayDouble(try validateNil(self.array(of: Double.self))))
        case .boolArray:
            return DatabaseField(
                column: column,
                value: .arrayBool(try validateNil(self.array(of: Bool.self))))
        case .textArray:
            return DatabaseField(
                column: column,
                value: .arrayString(try validateNil(self.array(of: String.self))))
        case .timestampArray:
            return DatabaseField(
                column: column,
                value: .arrayDate(try validateNil(self.array(of: Date.self))))
        case .jsonbArray:
            return DatabaseField(
                column: column,
                value: .arrayJSON(try validateNil(self.array(of: Data.self))))
        case .uuidArray:
            return DatabaseField(
                column: column,
                value: .arrayUUID(try validateNil(self.array(of: UUID.self))))
        default:
            throw PostgresError("Couldn't parse a `\(self.type)` from column '\(column)'. That Postgres datatype isn't supported, yet.")
        }
    }
}

extension DatabaseValue {
    func toPostgresData() -> PostgresData {
        switch self {
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

import Foundation
import MySQLNIO

extension MySQLData {
    private static let mysqlDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    private static let mysqlTimestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSX"
        return dateFormatter
    }()

    func toDatabaseField(from column: String) throws -> DatabaseField {

        func validateNil<T>(_ value: T?) throws -> T? {
            if self.buffer == nil {
                return nil
            } else {
                let errorMessage = "Unable to unwrap expected type `\(Swift.type(of: T.self))` from column "
                    + "'\(column)'."
                return try value.unwrap(or: MySQLError(errorMessage))
            }
        }

        switch self.type {
        case .int24, .short, .long, .longlong:
            return DatabaseField(column: column, value: .int(try validateNil(self.int)))
        case .tiny:
            return DatabaseField(column: column, value: .bool(try validateNil(self.bool)))
        case .varchar, .string, .varString:
            return DatabaseField(column: column, value: .string(try validateNil(self.string)))
        case .date, .timestamp, .timestamp2:
            return DatabaseField(column: column, value: .date(try validateNil(self.time?.date)))
        case .time:
            fatalError("Need to do these.")
        case .float, .decimal, .double:
            return DatabaseField(column: column, value: .double(try validateNil(self.double)))
        default:
            throw MySQLError("Couldn't parse a `\(self.type)` from column '\(column)'. That MySQL datatype isn't supported, yet.")
        }
    }
}

extension DatabaseValue {
    func toMySQLData() -> MySQLData {
        switch self {
        case .bool(let value):
            guard let value = value else { return .null }
            return MySQLData(bool: value)
        case .date(let value):
            guard let value = value else { return .null }
            return MySQLData(date: value)
        case .double(let value):
            guard let value = value else { return .null }
            return MySQLData(double: value)
        case .int(let value):
            guard let value = value else { return .null }
            return MySQLData(int: value)
        case .json(let value):
            fatalError()
        case .string(let value):
            guard let value = value else { return .null }
            return MySQLData(string: value)
        case .uuid(let value):
            guard let value = value else { return .null }
            return MySQLData(uuid: value)
        case .arrayInt(_):
            fatalError()
        case .arrayDouble(_):
            fatalError()
        case .arrayBool(_):
            fatalError()
        case .arrayString(_):
            fatalError()
        case .arrayDate(_):
            fatalError()
        case .arrayJSON(_):
            fatalError()
        case .arrayUUID(_):
            fatalError()
        }
    }
}

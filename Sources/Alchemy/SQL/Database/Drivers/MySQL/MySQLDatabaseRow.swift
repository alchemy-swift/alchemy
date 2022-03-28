import MySQLNIO
import MySQLKit
import NIO

extension SQLRow {
    init(mysql: MySQLRow) throws {
        self.init(
            fields: try mysql.columnDefinitions.map {
                guard let value = mysql.column($0.name) else {
                    preconditionFailure("MySQLRow had a key but no value for column \($0.name)!")
                }
                
                return SQLField(
                    column: $0.name,
                    value: try value.toSQLValue()) })
    }
}

extension MySQLData {
    /// Initialize from an Alchemy `SQLValue`.
    ///
    /// - Parameter value: The value with which to initialize. Given
    ///   the type of the value, the `MySQLData` will be initialized
    ///   with the best corresponding type.
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
        case .json(let value):
            self = MySQLData(type: .json, format: .text, buffer: ByteBuffer(data: value))
        case .string(let value):
            self = MySQLData(string: value)
        case .uuid(let value):
            self = MySQLData(string: value.uuidString)
        case .null:
            self = .null
        }
    }
    
    /// Converts a `MySQLData` to the Alchemy `SQLValue` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `MySQLData` to its expected type.
    /// - Returns: An `SQLValue` with the column, type and value,
    ///   best representing this `MySQLData`.
    func toSQLValue(_ column: String? = nil) throws -> SQLValue {
        switch self.type {
        case .int24, .short, .long, .longlong:
            return int.map { .int($0) } ?? .null
        case .tiny:
            return bool.map { .bool($0) } ?? .null
        case .varchar, .string, .varString, .blob, .tinyBlob, .mediumBlob, .longBlob:
            return string.map { .string($0) } ?? .null
        case .date, .timestamp, .timestamp2, .datetime, .datetime2:
            guard let date = time?.date else {
                return .null
            }
            
            return .date(date)
        case .float, .decimal, .double:
            return double.map { .double($0) } ?? .null
        case .json:
            guard let data = self.buffer?.data else {
                return .null
            }
            
            return .json(data)
        case .null:
            return .null
        default:
            let desc = column.map { "from column `\($0)`" } ?? "from MySQL column"
            throw DatabaseError("Couldn't parse a `\(type)` from \(desc). That MySQL datatype isn't supported, yet.")
        }
    }
}

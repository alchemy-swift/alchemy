import MySQLNIO
import MySQLKit
import NIO

final class MySQLDatabaseRow: SQLRow {
    let columns: Set<String>
    private let row: MySQLRow
    
    init(_ row: MySQLRow) {
        self.row = row
        self.columns = Set(self.row.columnDefinitions.map(\.name))
    }

    func get(_ column: String) throws -> SQLValue {
        try row.column(column)
            .unwrap(or: DatabaseError("No column named `\(column)` was found."))
            .toSQLValue(column)
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

import MySQLNIO
import MySQLKit
import NIO

public final class MySQLDatabaseRow: SQLRow {
    public let columns: Set<String>
    private let row: MySQLRow
    
    init(_ row: MySQLRow) {
        self.row = row
        self.columns = Set(self.row.columnDefinitions.map(\.name))
    }

    public func get(_ column: String) throws -> SQLValue {
        try self.row.column(column)
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
            self = value.map(MySQLData.init(bool:)) ?? .null
        case .date(let value):
            self = value.map(MySQLData.init(date:)) ?? .null
        case .double(let value):
            self = value.map(MySQLData.init(double:)) ?? .null
        case .int(let value):
            self = value.map(MySQLData.init(int:)) ?? .null
        case .json(let value):
            guard let data = value else {
                self = .null
                return
            }
            
            // `MySQLData` doesn't support initializing from
            // `Foundation.Data`.
            var buffer = ByteBufferAllocator().buffer(capacity: data.count)
            buffer.writeBytes(data)
            self = MySQLData(type: .string, format: .text, buffer: buffer, isUnsigned: true)
        case .string(let value):
            self = value.map(MySQLData.init(string:)) ?? .null
        case .uuid(let value):
            self = value.map(MySQLData.init(uuid:)) ?? .null
        }
    }
    
    /// Converts a `MySQLData` to the Alchemy `SQLValue` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `MySQLData` to its expected type.
    /// - Returns: An `SQLValue` with the column, type and value,
    ///   best representing this `MySQLData`.
    func toSQLValue(_ column: String) throws -> SQLValue {
        switch self.type {
        case .int24, .short, .long, .longlong:
            return .int(int)
        case .tiny:
            return .bool(bool)
        case .varchar, .string, .varString, .blob, .tinyBlob, .mediumBlob, .longBlob:
            return .string(string)
        case .date, .timestamp, .timestamp2, .datetime, .datetime2:
            return .date(time?.date)
        case .float, .decimal, .double:
            return .double(double)
        case .json:
            guard var buffer = self.buffer else {
                return .json(nil)
            }
            
            let data = buffer.readData(length: buffer.writerIndex)
            return .json(data)
        case .null:
            return .string(nil)
        default:
            throw DatabaseError("Couldn't parse a `\(type)` from column '\(column)'. That MySQL datatype isn't supported, yet.")
        }
    }
}

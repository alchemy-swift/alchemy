import MySQLNIO
import MySQLKit
import NIO

extension MySQLRow: DatabaseRow {
    public var allColumns: [String] {
        self.columnDefinitions.map(\.orgName)
    }

    public func getField(column: String) throws -> DatabaseField {
        try self.column(column)
            .unwrap(or: DatabaseError("No column named '\(column)' was found."))
            .toDatabaseField(from: column)
    }
}

extension MySQLData {
    /// Initialize from an Alchemy `DatabaseValue`.
    ///
    /// - Parameter value: The value with which to initialize. Given
    ///   the type of the value, the `MySQLData` will be initialized
    ///   with the best corresponding type.
    init(_ value: DatabaseValue) {
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
    
    /// Converts a `MySQLData` to the Alchemy `DatabaseField` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `MySQLData` to its expected type.
    /// - Returns: A `DatabaseField` with the column, type and value,
    ///   best representing this `MySQLData`.
    func toDatabaseField(from column: String) throws -> DatabaseField {
        func validateNil<T>(_ value: T?) throws -> T? {
            if self.buffer == nil {
                return nil
            } else {
                let errorMessage = "Unable to unwrap expected type "
                    + "`\(Swift.type(of: T.self))` from column '\(column)'."
                return try value.unwrap(or: DatabaseError(errorMessage))
            }
        }

        switch self.type {
        case .int24, .short, .long, .longlong:
            let value = DatabaseValue.int(try validateNil(self.int))
            return DatabaseField(column: column, value: value)
        case .tiny:
            let value = DatabaseValue.bool(try validateNil(self.bool))
            return DatabaseField(column: column, value: value)
        case .varchar, .string, .varString:
            let value = DatabaseValue.string(try validateNil(self.string))
            return DatabaseField(column: column, value: value)
        case .date, .timestamp, .timestamp2, .datetime, .datetime2:
            let value = DatabaseValue.date(try validateNil(self.time?.date))
            return DatabaseField(column: column, value: value)
        case .time:
            throw DatabaseError("Times aren't supported yet.")
        case .float, .decimal, .double:
            let value = DatabaseValue.double(try validateNil(self.double))
            return DatabaseField(column: column, value: value)
        case .json:
            guard var buffer = self.buffer else {
                return DatabaseField(column: column, value: .json(nil))
            }
            
            let data = buffer.readData(length: buffer.writerIndex)
            return DatabaseField(column: column, value: .json(data))
        default:
            let errorMessage = "Couldn't parse a `\(self.type)` from column "
                + "'\(column)'. That MySQL datatype isn't supported, yet."
            throw DatabaseError(errorMessage)
        }
    }
}

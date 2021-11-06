import PostgresNIO

public struct PostgresDatabaseRow: SQLRow {
    public let columns: Set<String>
    
    private let row: PostgresRow
    
    init(_ row: PostgresRow) {
        self.row = row
        self.columns = Set(self.row.rowDescription.fields.map(\.name))
    }
    
    public func get(_ column: String) throws -> SQLValue {
        try self.row.column(column)
            .unwrap(or: DatabaseError("No column named `\(column)` was found \(columns)."))
            .toSQLValue(column)
    }
}

extension PostgresData {
    /// Initialize from an Alchemy `SQLValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given
    ///   the type of the value, the `PostgresData` will be
    ///   initialized with the best corresponding type.
    init(_ value: SQLValue) {
        switch value {
        case .bool(let value):
            self = value.map(PostgresData.init(bool:)) ?? PostgresData(type: .bool)
        case .date(let value):
            self = value.map(PostgresData.init(date:)) ?? PostgresData(type: .date)
        case .double(let value):
            self = value.map(PostgresData.init(double:)) ?? PostgresData(type: .float8)
        case .int(let value):
            self = value.map(PostgresData.init(int:)) ?? PostgresData(type: .int4)
        case .json(let value):
            self = value.map(PostgresData.init(json:)) ?? PostgresData(type: .json)
        case .string(let value):
            self = value.map(PostgresData.init(string:)) ?? PostgresData(type: .text)
        case .uuid(let value):
            self = value.map(PostgresData.init(uuid:)) ?? PostgresData(type: .uuid)
        }
    }
    
    /// Converts a `PostgresData` to the Alchemy `SQLValue` type.
    ///
    /// - Parameter column: The name of the column this data is at.
    /// - Throws: A `DatabaseError` if there is an issue converting
    ///   the `PostgresData` to its expected type.
    /// - Returns: An `SQLValue` with the column, type and value,
    ///   best representing this `PostgresData`.
    func toSQLValue(_ column: String) throws -> SQLValue {
        // Ensures that if value is nil, it's because the database
        // column is actually nil and not because we are attempting
        // to pull out the wrong type.
        func validateNil<T>(_ value: T?) throws -> T? {
            guard self.value != nil else {
                return nil
            }
            
            let errorMessage = "Unable to unwrap expected type `\(name(of: T.self))` from column '\(column)'."
            return try value.unwrap(or: DatabaseError(errorMessage))
        }
        
        switch self.type {
        case .int2, .int4, .int8:
            return .int(try validateNil(self.int))
        case .bool:
            return .bool(try validateNil(self.bool))
        case .varchar, .text:
            return .string(try validateNil(self.string))
        case .date:
            return .date(try validateNil(self.date))
        case .timestamptz, .timestamp:
            return .date(try validateNil(self.date))
        case .float4, .float8:
            return .double(try validateNil(self.double))
        case .uuid:
            // The `PostgresNIO` `UUID` parser doesn't seem to work
            // properly `self.uuid` returns nil.
            return .uuid(try validateNil(self.uuid))
        case .json, .jsonb:
            return .json(try validateNil(self.json))
        default:
            throw DatabaseError("Couldn't parse a `\(type)` from column '\(column)'. That Postgres datatype isn't supported, yet.")
        }
    }
}

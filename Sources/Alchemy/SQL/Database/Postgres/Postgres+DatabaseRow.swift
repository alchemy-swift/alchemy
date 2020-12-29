import PostgresNIO

extension PostgresRow: DatabaseRow {
    // MARK: DatabaseRow
    
    public var allColumns: [String] {
        self.rowDescription.fields.map(\.name)
    }
    
    public func getField(column: String) throws -> DatabaseField {
        try self.column(column)
            .unwrap(or: DatabaseError("No column named `\(column)` was found."))
            .toDatabaseField(from: column)
    }
}

extension PostgresData {
    /// Initialize from an Alchemy `DatabaseValue`.
    ///
    /// - Parameter value: the value with which to initialize. Given the type of
    ///                    the value, the `PostgresData` will be initialized
    ///                    with the best corresponding type.
    init(_ value: DatabaseValue) {
        switch value {
        case .bool(let value):
            self = value.map(PostgresData.init(bool:)) ?? .null
        case .date(let value):
            self = value.map(PostgresData.init(date:)) ?? .null
        case .double(let value):
            self = value.map(PostgresData.init(double:)) ?? .null
        case .int(let value):
            self = value.map(PostgresData.init(int:)) ?? .null
        case .json(let value):
            self = value.map(PostgresData.init(json:)) ?? .null
        case .string(let value):
            self = value.map(PostgresData.init(string:)) ?? .null
        case .uuid(let value):
            self = value.map(PostgresData.init(uuid:)) ?? .null
        }
    }
    
    /// Converts a `PostgresData` to the Alchemy `DatabaseField` type.
    ///
    /// - Parameter column: the name of the column this data is at.
    /// - Throws: a `DatabaseError` if there is an issue converting the
    ///           `PostgresData` to its expected type.
    /// - Returns: a `DatabaseField` with the column, type and value, best
    ///            representing this PostgresData.
    fileprivate func toDatabaseField(
        from column: String
    ) throws -> DatabaseField {
        // Ensures that if value is nil, it's because the database column is
        // actually nil and not because we are attempting to pull out the wrong
        // type.
        func validateNil<T>(_ value: T?) throws -> T? {
            if self.value == nil {
                return nil
            } else {
                let errorMessage = "Unable to unwrap expected type"
                    + " `\(name(of: T.self))` from column '\(column)'."
                return try value.unwrap(or: DatabaseError(errorMessage))
            }
        }
        
        switch self.type {
        case .int2, .int4, .int8:
            let value = DatabaseValue.int(try validateNil(self.int))
            return DatabaseField(column: column, value: value)
        case .bool:
            let value = DatabaseValue.bool(try validateNil(self.bool))
            return DatabaseField(column: column, value: value)
        case .varchar, .text:
            let value = DatabaseValue.string(try validateNil(self.string))
            return DatabaseField(column: column, value: value)
        case .date:
            let value = DatabaseValue.date(try validateNil(self.date))
            return DatabaseField(column: column, value: value)
        case .timestamptz, .timestamp:
            let value = DatabaseValue.date(try validateNil(self.date))
            return DatabaseField(column: column, value: value)
        case .time, .timetz:
            fatalError("Times aren't supported yet.")
        case .float4, .float8:
            let value = DatabaseValue.double(try validateNil(self.double))
            return DatabaseField(column: column, value: value)
        case .uuid:
            // The `PostgresNIO` `UUID` parser doesn't seem to work properly
            // `self.uuid` returns nil.
            let string = try validateNil(self.string)
            let uuid = try string.map { string -> UUID in
                guard let uuid = UUID(uuidString: string) else {
                    throw DatabaseError(
                        "Invalid UUID '\(string)' at column '\(column)'"
                    )
                }
                
                return uuid
            }
            return DatabaseField(column: column, value: .uuid(uuid))
        case .json, .jsonb:
            let value = DatabaseValue.json(try validateNil(self.json))
            return DatabaseField(column: column, value: value)
        default:
            throw DatabaseError("Couldn't parse a `\(self.type)` from column "
                                    + "'\(column)'. That Postgres datatype "
                                    + "isn't supported, yet.")
        }
    }
}

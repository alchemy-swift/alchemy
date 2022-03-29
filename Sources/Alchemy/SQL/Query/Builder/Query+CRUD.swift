extension Query {
    /// Run a select query and return the database rows.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The rows returned by the database.
    public func getRows(_ columns: [String]? = nil) async throws -> [SQLRow] {
        if let columns = columns {
            self.columns = columns
        }
        
        let sql = try database.grammar.compileSelect(
            table: table,
            isDistinct: isDistinct,
            columns: self.columns,
            joins: joins,
            wheres: wheres,
            groups: groups,
            havings: havings,
            orders: orders,
            limit: limit,
            offset: offset,
            lock: lock)
        return try await database.query(sql.statement, values: sql.bindings)
    }

    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func firstRow(_ columns: [String]? = nil) async throws -> SQLRow? {
        try await limit(1).getRows(columns).first
    }

    /// Run a select query that looks for a single row matching the
    /// given database column and value.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The row from the database, if it exists.
    public func findRow(_ column: String, equals value: SQLValue, columns: [String]? = nil) async throws -> SQLRow? {
        wheres.append(column == value)
        return try await limit(1).getRows(columns).first
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameter column: What column to count. Defaults to `*`.
    /// - Returns: The count returned by the database.
    public func count(column: String = "*") async throws -> Int {
        guard let row = try await select(["COUNT(\(column))"]).firstRow() else {
            throw DatabaseError("a COUNT query didn't return any rows")
        }
        
        guard let field = row.fields.first else {
            throw DatabaseError("a COUNT query didn't return any columns")
        }
        
        return try field.value.int()
    }

    /// Perform an insert and create a database row from the provided
    /// data.
    ///
    /// - Parameter value: A dictionary containing the values to be
    ///   inserted.
    public func insert(_ value: [String: SQLValueConvertible]) async throws {
        try await insert([value])
    }

    /// Perform an insert and create database rows from the provided data.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    public func insert(_ values: [[String: SQLValueConvertible]]) async throws {
        guard !values.isEmpty else { return }
        let sql = database.grammar.compileInsert(table, values: values)
        _ = try await database.query(sql.statement, values: sql.bindings)
        return
    }
    
    public func insertReturn(_ values: [String: SQLValueConvertible]) async throws -> [SQLRow] {
        try await insertReturn([values])
    }
    
    /// Perform an insert and return the inserted records.
    ///
    /// - Parameter values: An array of dictionaries containing the values to be
    ///   inserted.
    /// - Returns: The inserted rows.
    public func insertReturn(_ values: [[String: SQLValueConvertible]]) async throws -> [SQLRow] {
        guard !values.isEmpty else { return [] }
        let statements = database.grammar.compileInsertReturn(table, values: values)
        return try await database.transaction { conn in
            var toReturn: [SQLRow] = []
            for sql in statements {
                toReturn.append(contentsOf: try await conn.query(sql.statement, values: sql.bindings))
            }
            
            return toReturn
        }
    }

    /// Perform an update on all data matching the query in the
    /// builder with the values provided.
    ///
    /// For example, if you wanted to update the first name of a user
    /// whose ID equals 10, you could do so as follows:
    /// ```swift
    /// database
    ///     .table("users")
    ///     .where("id" == 10)
    ///     .update(values: [
    ///         "first_name": "Ashley"
    ///     ])
    /// ```
    ///
    /// - Parameter values: An dictionary containing the values to be
    ///   updated.
    public func update(values: [String: SQLValueConvertible]) async throws {
        guard !values.isEmpty else { return }
        let sql = try database.grammar.compileUpdate(table, joins: joins, wheres: wheres, values: values)
        _ = try await database.query(sql.statement, values: sql.bindings)
    }

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        let sql = try database.grammar.compileDelete(table, wheres: wheres)
        _ = try await database.query(sql.statement, values: sql.bindings)
    }
}

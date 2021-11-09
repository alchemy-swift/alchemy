extension Query {
    /// Run a select query and return the database rows.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The rows returned by the database.
    public func get(_ columns: [String]? = nil) async throws -> [SQLRow] {
        if let columns = columns {
            self.columns = columns
        }
        
        let sql = try self.database.grammar.compileSelect(query: self)
        return try await database.runRawQuery(sql.statement, values: sql.bindings)
    }

    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func first(_ columns: [String]? = nil) async throws -> SQLRow? {
        try await limit(1).get(columns).first
    }

    /// Run a select query that looks for a single row matching the
    /// given database column and value.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The row from the database, if it exists.
    public func find(_ column: String, equals value: SQLValue, columns: [String]? = nil) async throws -> SQLRow? {
        wheres.append(column == value)
        return try await limit(1).get(columns).first
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameters:
    ///   - column: What column to count. Defaults to `*`.
    ///   - name: The alias that can be used for renaming the returned
    ///     count.
    /// - Returns: The count returned by the database.
    public func count(column: String = "*", as name: String? = nil) async throws -> Int {
        var query = "COUNT(\(column))"
        if let name = name {
            query += " as \(name)"
        }
        let row = try await select([query]).first()
            .unwrap(or: DatabaseError("a COUNT query didn't return any rows"))
        let column = try row.columns.first
            .unwrap(or: DatabaseError("a COUNT query didn't return any columns"))
        return try row.get(column).value.int()
    }

    /// Perform an insert and create a database row from the provided
    /// data.
    ///
    /// - Parameter value: A dictionary containing the values to be
    ///   inserted.
    /// - Parameter returnItems: Indicates whether the inserted items
    ///   should be returned with any fields updated/set by the
    ///   insert. Defaults to `true`. This flag doesn't affect
    ///   Postgres which always returns inserted items, but on MySQL
    ///   it means this will run two queries; one to insert and one to
    ///   fetch.
    /// - Returns: The inserted rows.
    public func insert(_ value: [String: SQLValueConvertible], returnItems: Bool = true) async throws -> [SQLRow] {
        try await insert([value], returnItems: returnItems)
    }

    /// Perform an insert and create database rows from the provided
    /// data.
    ///
    /// - Parameter values: An array of dictionaries containing the
    ///   values to be inserted.
    /// - Parameter returnItems: Indicates whether the inserted items
    ///   should be returned with any fields updated/set by the
    ///   insert. Defaults to `true`. This flag doesn't affect
    ///   Postgres which always runs a single query and returns
    ///   inserted items. On MySQL it means this will run two queries
    ///   _per value_; one to insert and one to fetch. If this is
    ///   `false`, MySQL will run a single query inserting all values.
    /// - Returns: The inserted rows.
    public func insert(_ values: [[String: SQLValueConvertible]], returnItems: Bool = true) async throws -> [SQLRow] {
        try await database.grammar.insert(from, values: values, database: self.database, returnItems: returnItems)
    }

    /// Perform an update on all data matching the query in the
    /// builder with the values provided.
    ///
    /// For example, if you wanted to update the first name of a user
    /// whose ID equals 10, you could do so as follows:
    /// ```swift
    /// Query
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
        let sql = try database.grammar.compileUpdate(from, joins: joins, wheres: wheres, values: values)
        _ = try await database.runRawQuery(sql.statement, values: sql.bindings)
    }

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        let sql = try database.grammar.compileDelete(from, wheres: wheres)
        _ = try await database.runRawQuery(sql.statement, values: sql.bindings)
    }
}

extension Database {
    /// Shortcut for running a query with the given table on
    /// `Database.default`.
    ///
    /// - Parameter table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public static func table(_ table: String) -> Query {
        Database.default.table(table)
    }

    /// Shortcut for running a query with the given table on
    /// `Database.default`.
    ///
    /// An alias for `table(_ table: String)` to be used when running
    /// a `select` query that also lets you alias the table name.
    ///
    /// - Parameters:
    ///   - table: The table to select data from.
    ///   - alias: An alias to use in place of table name. Defaults to
    ///     `nil`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public static func from(_ table: String, as alias: String? = nil) -> Query {
        guard let alias = alias else {
            return Database.table(table)
        }
        
        return Database.table("\(table) as \(alias)")
    }
    
    /// Start a QueryBuilder query on this database. See `Query` or
    /// QueryBuilder guides.
    ///
    /// Usage:
    /// ```swift
    /// if let row = try await database.table("users").where("id" == 1).first() {
    ///     print("Got a row with fields: \(row.allColumns)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func table(_ table: String) -> Query {
        Query(database: driver, from: table)
    }

    /// An alias for `table(_ table: String)` to be used when running.
    /// a `select` query that also lets you alias the table name.
    ///
    /// - Parameters:
    ///   - table: The table to select data from.
    ///   - alias: An alias to use in place of table name. Defaults to
    ///     `nil`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func from(_ table: String, as alias: String? = nil) -> Query {
        guard let alias = alias else {
            return self.table(table)
        }
        
        return self.table("\(table) as \(alias)")
    }
}


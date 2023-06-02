extension Query {
    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func first(_ columns: [String]? = nil) async throws -> Result? {
        try await limit(1).get(columns).first
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameter column: What column to count. Defaults to `*`.
    /// - Returns: The count returned by the database.
    public func count(column: String = "*") async throws -> Int {
        guard let field = try await (select(["COUNT(\(column))"]).first() as? SQLRow)?.fields.first else {
            throw DatabaseError("a COUNT query didn't return any data")
        }

        return try field.value.int()
    }
}

extension Database {
    @discardableResult
    func query(sql: SQL, log: Bool) async throws -> [SQLRow] {
        if log || shouldLog {
            let bindingsString = sql.bindings.isEmpty ? "" : " \(sql.bindings)"
            Log.info("\(sql.statement);\(bindingsString)")
        }

        return try await query(sql.statement, values: sql.bindings)
    }

    var dialect: SQLDialect {
        provider.dialect
    }
}

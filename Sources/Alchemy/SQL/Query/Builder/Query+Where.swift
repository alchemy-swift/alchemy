extension Query {
    /// Add a basic where clause to the query to filter down results.
    ///
    /// - Parameters:
    ///   - clause: A `WhereValue` clause matching a column to a given
    ///     value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func `where`(_ clause: WhereValue) -> Self {
        self.wheres.append(clause)
        return self
    }

    /// An alias for `where(_ clause: WhereValue) ` that appends an or
    /// clause instead of an and clause.
    ///
    /// - Parameters:
    ///   - clause: A `WhereValue` clause matching a column to a given
    ///     value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhere(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        return self.where(clause)
    }

    /// Add a nested where clause that is a group of combined clauses.
    /// This can be used for logically grouping where clauses like
    /// you would inside of an if statement. Each clause is
    /// wrapped in parenthesis.
    ///
    /// For example if you want to logically ensure a user is under 30
    /// and named Paul, or over the age of 50 having any name, you
    /// could use a nested where clause along with a separate
    /// where value clause:
    /// ```swift
    /// Query
    /// .from("users")
    /// .where {
    ///     $0.where("age" < 30)
    ///      .orWhere("first_name" == "Paul")
    /// }
    /// .where("age" > 50)
    /// ```
    ///
    /// - Parameters:
    ///   - closure: A `WhereNestedClosure` that provides a nested
    ///     clause to attach nested where clauses to.
    ///   - boolean: How the clause should be appended(`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func `where`(_ closure: @escaping WhereNestedClosure, boolean: WhereBoolean = .and) -> Self {
        self.wheres.append(
            WhereNested(
                database: database,
                closure: closure,
                boolean: boolean
            )
        )
        return self
    }

    /// A helper for adding an **or** `where` nested closure clause.
    ///
    /// - Parameters:
    ///   - closure: A `WhereNestedClosure` that provides a nested
    ///     query to attach nested where clauses to.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhere(_ closure: @escaping WhereNestedClosure) -> Self {
        self.where(closure, boolean: .or)
    }

    /// Add a clause requiring that a column match any values in a
    /// given array.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    ///   - type: How the match should happen (*in* or *notIn*).
    ///     Defaults to `.in`.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func `where`(
        key: String,
        in values: [SQLValueConvertible],
        type: WhereIn.InType = .in,
        boolean: WhereBoolean = .and
    ) -> Self {
        self.wheres.append(WhereIn(
            key: key,
            values: values.map { $0.value },
            type: type,
            boolean: boolean)
        )
        return self
    }

    /// A helper for adding an **or** variant of the `where(key:in:)` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    ///   - type: How the match should happen (`.in` or `.notIn`).
    ///     Defaults to `.in`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhere(key: String, in values: [SQLValueConvertible], type: WhereIn.InType = .in) -> Self {
        return self.where(
            key: key,
            in: values,
            type: type,
            boolean: .or
        )
    }

    /// Add a clause requiring that a column not match any values in a
    /// given array. This is a helper method for the where in method.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereNot(key: String, in values: [SQLValueConvertible], boolean: WhereBoolean = .and) -> Self {
        return self.where(key: key, in: values, type: .notIn, boolean: boolean)
    }

    /// A helper for adding an **or** `whereNot` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNot(key: String, in values: [SQLValueConvertible]) -> Self {
        self.where(key: key, in: values, type: .notIn, boolean: .or)
    }

    /// Add a raw SQL where clause to your query.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - bindings: Any variables for binding in the SQL.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereRaw(sql: String, bindings: [SQLValueConvertible], boolean: WhereBoolean = .and) -> Self {
        self.wheres.append(WhereRaw(
            query: sql,
            values: bindings.map { $0.value },
            boolean: boolean)
        )
        return self
    }

    /// A helper for adding an **or** `whereRaw` clause.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - bindings: Any variables for binding in the SQL.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereRaw(sql: String, bindings: [SQLValueConvertible]) -> Self {
        self.whereRaw(sql: sql, bindings: bindings, boolean: .or)
    }

    /// Add a where clause requiring that two columns match each other
    ///
    /// - Parameters:
    ///   - first: The first column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - second: The second column to match against.
    ///   - boolean: How the clause should be appended (`.and`
    ///     or `.or`).
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    @discardableResult
    public func whereColumn(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> Self {
        wheres.append(WhereColumn(first: first, op: op, second: second, boolean: boolean))
        return self
    }

    /// A helper for adding an **or** `whereColumn` clause.
    ///
    /// - Parameters:
    ///   - first: The first column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - second: The second column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereColumn(first: String, op: Operator, second: String) -> Self {
        self.whereColumn(first: first, op: op, second: second, boolean: .or)
    }

    /// Add a where clause requiring that a column be null.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`).
    ///   - not: Should the value be null or not null.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereNull(
        key: String,
        boolean: WhereBoolean = .and,
        not: Bool = false
    ) -> Self {
        let action = not ? "IS NOT" : "IS"
        self.wheres.append(WhereRaw(
            query: "\(key) \(action) NULL",
            boolean: boolean)
        )
        return self
    }

    /// A helper for adding an **or** `whereNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNull(key: String) -> Self {
        self.whereNull(key: key, boolean: .or)
    }

    /// Add a where clause requiring that a column not be null.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`).
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereNotNull(key: String, boolean: WhereBoolean = .and) -> Self {
        self.whereNull(key: key, boolean: boolean, not: true)
    }

    /// A helper for adding an **or** `whereNotNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNotNull(key: String) -> Self {
        self.whereNotNull(key: key, boolean: .or)
    }
}

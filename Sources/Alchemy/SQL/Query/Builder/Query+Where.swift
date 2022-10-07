protocol WhereClause: SQLConvertible {}

extension Query {
    public indirect enum WhereType: Equatable {
        case value(key: String, op: Operator, value: SQLValue)
        case column(first: String, op: Operator, second: String)
        case nested(wheres: [Where])
        case `in`(key: String, values: [SQLValue], type: WhereInType)
        case raw(SQL)
    }
    
    public enum WhereBoolean: String {
        case and
        case or
    }
    
    public enum WhereInType: String {
        case `in`
        case notIn = "not in"
    }
    
    public struct Where: Equatable {
        public let type: WhereType
        public let boolean: WhereBoolean
    }

    /// Add a basic where clause to the query to filter down results.
    ///
    /// - Parameters:
    ///   - clause: A `WhereValue` clause matching a column to a given
    ///     value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func `where`(_ clause: Where) -> Self {
        wheres.append(clause)
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
    public func orWhere(_ clause: Where) -> Self {
        `where`(Where(type: clause.type, boolean: .or))
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
    public func `where`(_ closure: @escaping (Query) -> Query, boolean: WhereBoolean = .and) -> Self {
        let query = closure(Query(database: database, table: table))
        wheres.append(Where(type: .nested(wheres: query.wheres), boolean: boolean))
        return self
    }

    /// A helper for adding an **or** `where` nested closure clause.
    ///
    /// - Parameters:
    ///   - closure: A `WhereNestedClosure` that provides a nested
    ///     query to attach nested where clauses to.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhere(_ closure: @escaping (Query) -> Query) -> Self {
        `where`(closure, boolean: .or)
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
    public func `where`(key: String, in values: [SQLValueConvertible], type: WhereInType = .in, boolean: WhereBoolean = .and) -> Self {
        wheres.append(Where(type: .in(key: key, values: values.map { $0.sqlValue }, type: type), boolean: boolean))
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
    public func orWhere(key: String, in values: [SQLValueConvertible], type: WhereInType = .in) -> Self {
        `where`(key: key, in: values, type: type, boolean: .or)
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
        `where`(key: key, in: values, type: .notIn, boolean: boolean)
    }

    /// A helper for adding an **or** `whereNot` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNot(key: String, in values: [SQLValueConvertible]) -> Self {
        `where`(key: key, in: values, type: .notIn, boolean: .or)
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
        wheres.append(Where(type: .raw(SQL(sql, bindings: bindings.map(\.sqlValue))), boolean: boolean))
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
        whereRaw(sql: sql, bindings: bindings, boolean: .or)
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
        wheres.append(Where(type: .column(first: first, op: op, second: second), boolean: boolean))
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
        whereColumn(first: first, op: op, second: second, boolean: .or)
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
    public func whereNull(key: String, boolean: WhereBoolean = .and, not: Bool = false) -> Self {
        let action = not ? "IS NOT" : "IS"
        wheres.append(Where(type: .raw(SQL("\(key) \(action) NULL")), boolean: boolean))
        return self
    }

    /// A helper for adding an **or** `whereNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNull(key: String) -> Self {
        whereNull(key: key, boolean: .or)
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
        whereNull(key: key, boolean: boolean, not: true)
    }

    /// A helper for adding an **or** `whereNotNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNotNull(key: String) -> Self {
        whereNotNull(key: key, boolean: .or)
    }
}

extension String {
    // MARK: Custom Swift Operators
    
    public static func == (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .equals, value: rhs.sqlValue), boolean: .and)
    }

    public static func != (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .notEqualTo, value: rhs.sqlValue), boolean: .and)
    }

    public static func < (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .lessThan, value: rhs.sqlValue), boolean: .and)
    }

    public static func > (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .greaterThan, value: rhs.sqlValue), boolean: .and)
    }

    public static func <= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .lessThanOrEqualTo, value: rhs.sqlValue), boolean: .and)
    }

    public static func >= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .greaterThanOrEqualTo, value: rhs.sqlValue), boolean: .and)
    }

    public static func ~= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .like, value: rhs.sqlValue), boolean: .and)
    }
}

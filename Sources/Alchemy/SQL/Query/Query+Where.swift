public struct SQLWhere: Hashable {
    public enum Boolean: String, Hashable {
        case and
        case or
    }

    public indirect enum WhereType: Hashable {
        case value(key: String, op: Operator, value: SQL)
        case column(first: String, op: Operator, second: String)
        case nested(wheres: [SQLWhere])
        case `in`(key: String, values: [SQL])
        case notIn(key: String, values: [SQL])
        case raw(SQL)

        public func hash(into hasher: inout Swift.Hasher) {
            hasher.combine("\(self)")
        }
    }

    public enum Operator: CustomStringConvertible, Equatable {
        case equals
        case lessThan
        case greaterThan
        case lessThanOrEqualTo
        case greaterThanOrEqualTo
        case notEqualTo
        case like
        case notLike
        case raw(String)

        public var description: String {
            switch self {
            case .equals: return "="
            case .lessThan: return "<"
            case .greaterThan: return ">"
            case .lessThanOrEqualTo: return "<="
            case .greaterThanOrEqualTo: return ">="
            case .notEqualTo: return "!="
            case .like: return "LIKE"
            case .notLike: return "NOT LIKE"
            case .raw(let value): return value
            }
        }
    }
    
    public let boolean: Boolean
    public let type: WhereType

    static func and(_ type: WhereType) -> SQLWhere {
        SQLWhere(boolean: .and, type: type)
    }

    static func or(_ type: WhereType) -> SQLWhere {
        SQLWhere(boolean: .or, type: type)
    }
}

// MARK: - Where Operators

extension String {
    public static func == (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .equals, value: rhs.sql))
    }

    public static func != (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .notEqualTo, value: rhs.sql))
    }

    public static func < (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .lessThan, value: rhs.sql))
    }

    public static func > (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .greaterThan, value: rhs.sql))
    }

    public static func <= (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .lessThanOrEqualTo, value: rhs.sql))
    }

    public static func >= (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .greaterThanOrEqualTo, value: rhs.sql))
    }

    public static func ~= (lhs: String, rhs: SQLConvertible) -> SQLWhere {
        .and(.value(key: lhs, op: .like, value: rhs.sql))
    }
}

// MARK: - Builders

extension Query {
    /// Add a basic where clause to the query to filter down results.
    ///
    /// - Parameters:
    ///   - clause: A `WhereValue` clause matching a column to a given
    ///     value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func `where`(_ clause: SQLWhere) -> Self {
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
    public func orWhere(_ clause: SQLWhere) -> Self {
        `where`(.or(clause.type))
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
    public func `where`(_ closure: @escaping (Query) -> Query, boolean: SQLWhere.Boolean = .and) -> Self {
        let query = closure(Query(db: db, table: table))
        return `where`(SQLWhere(boolean: boolean, type: .nested(wheres: query.wheres)))
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
    public func `where`(_ key: String, in values: [SQLConvertible], boolean: SQLWhere.Boolean = .and) -> Self {
        guard !values.isEmpty else {
            return `where`(SQLWhere(boolean: boolean, type: .raw("FALSE")))
        }

        return `where`(SQLWhere(boolean: boolean, type: .in(key: key, values: values.map { $0.sql })))
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
    public func orWhere(_ key: String, in values: [SQLConvertible]) -> Self {
        `where`(key, in: values, boolean: .or)
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
    public func whereNot(_ key: String, in values: [SQLConvertible], boolean: SQLWhere.Boolean = .and) -> Self {
        guard !values.isEmpty else {
            return `where`(SQLWhere(boolean: boolean, type: .raw("TRUE")))
        }

        return `where`(SQLWhere(boolean: boolean, type: .notIn(key: key, values: values.map { $0.sql })))
    }

    /// A helper for adding an **or** `whereNot` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNot(_ key: String, in values: [SQLConvertible]) -> Self {
        whereNot(key, in: values, boolean: .or)
    }

    /// Add a raw SQL where clause to your query.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - parameters: Any variables for binding in the SQL.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereRaw(_ sql: String, parameters: [SQLConvertible], boolean: SQLWhere.Boolean = .and) -> Self {
        `where`(SQLWhere(boolean: boolean, type: .raw(SQL(sql, parameters: parameters))))
    }

    /// A helper for adding an **or** `whereRaw` clause.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - parameters: Any variables for binding in the SQL.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereRaw(_ sql: String, parameters: [SQLConvertible]) -> Self {
        whereRaw(sql, parameters: parameters, boolean: .or)
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
    public func whereColumn(first: String, op: SQLWhere.Operator, second: String, boolean: SQLWhere.Boolean = .and) -> Self {
        `where`(SQLWhere(boolean: boolean, type: .column(first: first, op: op, second: second)))
    }

    /// A helper for adding an **or** `whereColumn` clause.
    ///
    /// - Parameters:
    ///   - first: The first column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - second: The second column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereColumn(first: String, op: SQLWhere.Operator, second: String) -> Self {
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
    public func whereNull(_ key: String, boolean: SQLWhere.Boolean = .and) -> Self {
        `where`(SQLWhere(boolean: boolean, type: .raw(SQL("\(key) IS NULL"))))
    }

    /// A helper for adding an **or** `whereNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNull(_ key: String) -> Self {
        whereNull(key, boolean: .or)
    }

    /// Add a where clause requiring that a column not be null.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`).
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereNotNull(_ key: String, boolean: SQLWhere.Boolean = .and) -> Self {
        `where`(SQLWhere(boolean: boolean, type: .raw(SQL("\(key) IS NOT NULL"))))
    }

    /// A helper for adding an **or** `whereNotNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNotNull(_ key: String) -> Self {
        whereNotNull(key, boolean: .or)
    }
}

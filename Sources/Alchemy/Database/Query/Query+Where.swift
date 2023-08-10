public struct SQLWhere: Hashable, SQLConvertible {
    public enum Boolean: String, Hashable {
        case and = "AND"
        case or = "OR"
    }

    public indirect enum Clause: Hashable {
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

    public let boolean: Boolean
    public let clause: SQLWhere.Clause

    public var sql: SQL {
        let boolean = boolean.rawValue
        switch clause {
        case .value(let key, let op, let sql):
            if sql == .null {
                if op == .notEqualTo {
                    return SQL("\(boolean) \(key) IS NOT NULL")
                } else if op == .equals {
                    return SQL("\(boolean) \(key) IS NULL")
                } else {
                    fatalError("Can't use any where operators other than .notEqualTo or .equals if the value is NULL.")
                }
            } else {
                return SQL("\(boolean) \(key) \(op) ?", input: [sql])
            }
        case .column(let first, let op, let second):
            return SQL("\(boolean) \(first) \(op) \(second)")
        case .nested(let wheres):
            let nestedSQL = wheres.joined()
            return SQL("\(boolean) (\(nestedSQL.statement))", parameters: nestedSQL.parameters)
        case .in(let key, let expressions):
            let placeholders = Array(repeating: "?", count: expressions.count).joined(separator: ", ")
            let isSelect = expressions.first.map { $0.statement.hasPrefix("SELECT") && expressions.count == 1 } ?? false
            let array = isSelect ? "\(placeholders)" : "(\(placeholders))"
            return SQL("\(boolean) \(key) IN \(array)", input: expressions)
        case .notIn(let key, let expressions):
            let placeholders = Array(repeating: "?", count: expressions.count).joined(separator: ", ")
            let isSelect = expressions.first.map { $0.statement.hasPrefix("SELECT") && expressions.count == 1 } ?? false
            let array = isSelect ? "\(placeholders)" : "(\(placeholders))"
            return SQL("\(boolean) \(key) NOT IN \(array)", input: expressions)
        case .raw(let sql):
            return SQL("\(boolean) \(sql.statement)", parameters: sql.parameters)
        }
    }

    public static func and(_ clause: SQLWhere.Clause) -> SQLWhere {
        SQLWhere(boolean: .and, clause: clause)
    }

    public static func or(_ clause: SQLWhere.Clause) -> SQLWhere {
        SQLWhere(boolean: .or, clause: clause)
    }
}

extension Array where Element == SQLWhere {
    public func joined() -> SQL {
        let sql = map(\.sql).joined()
        // drop the leading boolean
        let statement = sql.statement.components(separatedBy: " ").dropFirst().joined(separator: " ")
        return SQL(statement, parameters: sql.parameters)
    }
}


// MARK: - Where Operators

extension String {
    public static func == (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .equals, value: rhs.sql)
    }

    public static func != (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .notEqualTo, value: rhs.sql)
    }

    public static func < (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .lessThan, value: rhs.sql)
    }

    public static func > (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .greaterThan, value: rhs.sql)
    }

    public static func <= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .lessThanOrEqualTo, value: rhs.sql)
    }

    public static func >= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .greaterThanOrEqualTo, value: rhs.sql)
    }

    public static func ~= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(key: lhs, op: .like, value: rhs.sql)
    }
}

extension SQLWhere.Clause {
    public static func && (lhs: SQLWhere.Clause, rhs: SQLWhere.Clause) -> SQLWhere.Clause {
        switch (lhs, rhs) {
        case let (.nested(lhsWheres), .nested(rhsWheres)):
            return .nested(wheres: lhsWheres + rhsWheres)
        case let (.nested(wheres), _):
            return .nested(wheres: wheres + [.and(rhs)])
        case let (_, .nested(wheres)):
            return .nested(wheres: [.and(lhs)] + wheres)
        default:
            return .nested(wheres: [.and(lhs), .and(rhs)])
        }
    }

    public static func || (lhs: SQLWhere.Clause, rhs: SQLWhere.Clause) -> SQLWhere.Clause {
        switch (lhs, rhs) {
        case let (.nested(lhsWheres), .nested(rhsWheres)):
            return .nested(wheres: lhsWheres + rhsWheres)
        case let (.nested(wheres), _):
            return .nested(wheres: wheres + [.or(rhs)])
        case let (_, .nested(wheres)):
            guard let first = wheres.first else {
                return lhs
            }

            return .nested(wheres: [.and(lhs), SQLWhere(boolean: .or, clause: first.clause)] + wheres.dropFirst())
        default:
            return .nested(wheres: [.and(lhs), .or(rhs)])
        }
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
    public func `where`(_ clause: SQLWhere.Clause) -> Self {
        wheres.append(.and(clause))
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
    public func orWhere(_ clause: SQLWhere.Clause) -> Self {
        wheres.append(.or(clause))
        return self
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
    public func `where`(_ closure: @escaping (Query) -> Query) -> Self {
        let query = closure(Query(db: db, table: table))
        return `where`(.nested(wheres: query.wheres))
    }

    /// A helper for adding an **or** `where` nested closure clause.
    ///
    /// - Parameters:
    ///   - closure: A `WhereNestedClosure` that provides a nested
    ///     query to attach nested where clauses to.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhere(_ closure: @escaping (Query) -> Query) -> Self {
        let query = closure(Query(db: db, table: table))
        return orWhere(.nested(wheres: query.wheres))
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
    public func `where`(_ key: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("FALSE"))
        }

        return `where`(.in(key: key, values: values.map(\.sql)))
    }

    public func `where`(_ key: String, in query: Query<SQLRow>) -> Self {
        `where`(.in(key: key, values: [query.sql]))
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
        guard !values.isEmpty else {
            return orWhere(.raw("FALSE"))
        }

        return orWhere(.in(key: key, values: values.map(\.sql)))
    }

    public func orWhere(_ key: String, in query: Query<SQLRow>) -> Self {
        orWhere(.in(key: key, values: [query.sql]))
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
    public func whereNot(_ key: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("TRUE"))
        }

        return `where`(.notIn(key: key, values: values.map(\.sql)))
    }

    public func whereNot(_ key: String, in query: Query<SQLRow>) -> Self {
        `where`(.notIn(key: key, values: [query.sql]))
    }

    /// A helper for adding an **or** `whereNot` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNot(_ key: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return orWhere(.raw("TRUE"))
        }

        return orWhere(.notIn(key: key, values: values.map(\.sql)))
    }

    public func orWhereNot(_ key: String, in query: Query<SQLRow>) -> Self {
        orWhere(.notIn(key: key, values: [query.sql]))
    }

    /// Add a raw SQL where clause to your query.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - input: Any variables for binding in the SQL.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`). Defaults to `.and`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func whereRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        `where`(.raw(SQL(sql, parameters: parameters)))
    }

    /// A helper for adding an **or** `whereRaw` clause.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - parameters: Any variables for binding in the SQL.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        orWhere(.raw(SQL(sql, parameters: parameters)))
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
    public func whereColumn(first: String, op: SQLWhere.Clause.Operator, second: String) -> Self {
        `where`(.column(first: first, op: op, second: second))
    }

    /// A helper for adding an **or** `whereColumn` clause.
    ///
    /// - Parameters:
    ///   - first: The first column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - second: The second column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereColumn(first: String, op: SQLWhere.Clause.Operator, second: String) -> Self {
        orWhere(.column(first: first, op: op, second: second))
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
    public func whereNull(_ key: String) -> Self {
        `where`(.raw("\(key) IS NULL"))
    }

    /// A helper for adding an **or** `whereNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNull(_ key: String) -> Self {
        orWhere(.raw("\(key) IS NULL"))
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
        `where`(.raw("\(key) IS NOT NULL"))
    }

    /// A helper for adding an **or** `whereNotNull` clause.
    ///
    /// - Parameter key: The column to match against.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNotNull(_ key: String) -> Self {
        orWhere(.raw("\(key) IS NOT NULL"))
    }
}

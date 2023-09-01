public struct SQLWhere: Hashable, SQLConvertible {
    public enum Boolean: String, Hashable {
        case and = "AND"
        case or = "OR"
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

    public indirect enum Clause: Hashable {
        case raw(SQL)
        case value(column: String, op: Operator, value: SQL)
        case column(column: String, op: Operator, otherColumn: String)
        case nested(wheres: [SQLWhere])
        case `in`(column: String, values: [SQL])
        case notIn(column: String, values: [SQL])

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
    func joined() -> SQL {
        let sql = map(\.sql).joined()
        // drop the leading boolean
        let statement = sql.statement.components(separatedBy: " ").dropFirst().joined(separator: " ")
        return SQL(statement, parameters: sql.parameters)
    }
}

// MARK: - Operators

extension String {
    public static func == (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .equals, value: rhs.sql)
    }

    public static func != (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .notEqualTo, value: rhs.sql)
    }

    public static func < (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .lessThan, value: rhs.sql)
    }

    public static func > (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .greaterThan, value: rhs.sql)
    }

    public static func <= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .lessThanOrEqualTo, value: rhs.sql)
    }

    public static func >= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .greaterThanOrEqualTo, value: rhs.sql)
    }

    public static func ~= (lhs: String, rhs: SQLConvertible) -> SQLWhere.Clause {
        .value(column: lhs, op: .like, value: rhs.sql)
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

    // MARK: Value

    public func `where`(_ clause: SQLWhere.Clause) -> Self {
        wheres.append(.and(clause))
        return self
    }

    public func orWhere(_ clause: SQLWhere.Clause) -> Self {
        wheres.append(.or(clause))
        return self
    }

    public func `where`(_ column: String, _ op: SQLWhere.Operator, _ value: SQLConvertible) -> Self {
        `where`(.value(column: column, op: op, value: value.sql))
    }

    public func orWhere(_ column: String, _ op: SQLWhere.Operator, _ value: SQLConvertible) -> Self {
        orWhere(.value(column: column, op: op, value: value.sql))
    }

    // MARK: Nested

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
    /// DB.table("users")
    ///     .where {
    ///         $0.where("age" < 30)
    ///             .orWhere("first_name" == "Paul")
    ///     }
    ///     .where("age" > 50)
    /// ```
    public func `where`(_ closure: @escaping (Query) -> Query) -> Self {
        let query = closure(Query(db: db, table: table))
        return `where`(.nested(wheres: query.wheres))
    }

    /// A helper for adding an **or** `where` nested closure clause.
    public func orWhere(_ closure: @escaping (Query) -> Query) -> Self {
        let query = closure(Query(db: db, table: table))
        return orWhere(.nested(wheres: query.wheres))
    }

    // MARK: IN Array

    /// Add a clause requiring that a column match any values in a
    /// given array.
    public func `where`(_ column: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("FALSE"))
        }

        return `where`(.in(column: column, values: values.map(\.sql)))
    }

    /// A helper for adding an **or** variant of the `where(column:in:)` clause.
    public func orWhere(_ column: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return orWhere(.raw("FALSE"))
        }

        return orWhere(.in(column: column, values: values.map(\.sql)))
    }

    /// Add a clause requiring that a column not match any values in a
    /// given array. This is a helper method for the where in method.
    public func whereNot(_ column: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return `where`(.raw("TRUE"))
        }

        return `where`(.notIn(column: column, values: values.map(\.sql)))
    }

    /// A helper for adding an **or** `whereNot` clause.
    public func orWhereNot(_ column: String, in values: [SQLConvertible]) -> Self {
        guard !values.isEmpty else {
            return orWhere(.raw("TRUE"))
        }

        return orWhere(.notIn(column: column, values: values.map(\.sql)))
    }

    // MARK: IN Query

    public func `where`(_ column: String, in query: Query<SQLRow>) -> Self {
        `where`(.in(column: column, values: [query.sql]))
    }

    public func orWhere(_ column: String, in query: Query<SQLRow>) -> Self {
        orWhere(.in(column: column, values: [query.sql]))
    }

    public func whereNot(_ column: String, in query: Query<SQLRow>) -> Self {
        `where`(.notIn(column: column, values: [query.sql]))
    }

    public func orWhereNot(_ column: String, in query: Query<SQLRow>) -> Self {
        orWhere(.notIn(column: column, values: [query.sql]))
    }

    // MARK: Raw

    /// Add a raw SQL where clause to your query.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - parameters: Any variables for binding in the SQL.
    public func whereRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        `where`(.raw(SQL(sql, parameters: parameters)))
    }

    /// A helper for adding an **or** `whereRaw` clause.
    ///
    /// - Parameters:
    ///   - sql: A string representing the SQL where clause to be run.
    ///   - parameters: Any variables for binding in the SQL.
    public func orWhereRaw(_ sql: String, parameters: [SQLValue]) -> Self {
        orWhere(.raw(SQL(sql, parameters: parameters)))
    }

    // MARK: Column

    /// Add a where clause requiring that two columns match each other
    ///
    /// - Parameters:
    ///   - column: The first column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - otherColumn: The second column to match against.
    public func whereColumn(_ column: String, _ op: SQLWhere.Operator, _ otherColumn: String) -> Self {
        `where`(.column(column: column, op: op, otherColumn: otherColumn))
    }

    /// A helper for adding an **or** `whereColumn` clause.
    public func orWhereColumn(_ column: String, _ op: SQLWhere.Operator, _ otherColumn: String) -> Self {
        orWhere(.column(column: column, op: op, otherColumn: otherColumn))
    }

    // MARK: NULL

    /// Add a where clause requiring that a column be null.
    public func whereNull(_ column: String) -> Self {
        `where`(.raw("\(column) IS NULL"))
    }

    /// A helper for adding an **or** `whereNull` clause.
    public func orWhereNull(_ column: String) -> Self {
        orWhere(.raw("\(column) IS NULL"))
    }

    /// Add a where clause requiring that a column not be null.
    public func whereNotNull(_ column: String) -> Self {
        `where`(.raw("\(column) IS NOT NULL"))
    }

    /// A helper for adding an **or** `whereNotNull` clause.
    public func orWhereNotNull(_ column: String) -> Self {
        orWhere(.raw("\(column) IS NOT NULL"))
    }
}

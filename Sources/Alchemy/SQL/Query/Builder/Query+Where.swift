protocol WhereClause: SQLConvertible {}

extension Query {
    public enum WhereType {
        case value(key: String, op: Operator, value: SQLValue)
        case column(first: String, op: Operator, second: String)
        case nested(driver: DatabaseDriver, closure: (Query) -> Query, fromTable: String)
        case `in`(key: String, values: [SQLValue], type: WhereInType)
        case raw(SQL)
    }
    
    public enum WhereBoolean: String {
        case and
        case or
    }
    
    public enum WhereInType: String {
        case `in`
        case notIn
    }
    
    public struct Where: SQLConvertible {
        public let type: WhereType
        public var boolean: WhereBoolean = .and
        
        public var sql: SQL {
            switch type {
            case .value(let key, let op, let value):
                if value == .null {
                    if op == .notEqualTo {
                        return SQL("\(boolean) \(key) IS NOT NULL")
                    } else if op == .equals {
                        return SQL("\(boolean) \(key) IS NULL")
                    } else {
                        fatalError("Can't use any where operators other than .notEqualTo or .equals if the value is NULL.")
                    }
                } else {
                    return SQL("\(boolean) \(key) \(op) ?", bindings: [value])
                }
            case .column(let first, let op, let second):
                return SQL("\(boolean) \(first) \(op) \(second)")
            case .nested(let driver, let closure, let fromTable):
                let query = closure(Query(database: driver, from: fromTable))
                let nestedSQL = query.wheres.joined().droppingLeadingBoolean()
                return SQL("\(boolean) (\(nestedSQL))", bindings: nestedSQL.bindings)
            case .in(let key, let values, let type):
                let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
                return SQL("\(boolean) \(key) \(type)(\(placeholders))", bindings: values)
            case .raw(let sql):
                return SQL("\(boolean) \(sql.statement)", bindings: sql.bindings)
            }
        }
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
        var clause = clause
        clause.boolean = .or
        return `where`(clause)
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
        wheres.append(Where(type: .nested(driver: database, closure: closure, fromTable: from), boolean: boolean))
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
        wheres.append(Where(type: .in(key: key, values: values.map { $0.value }, type: type), boolean: boolean))
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
        wheres.append(Where(type: .raw(SQL(sql, bindings: bindings.map(\.value))), boolean: boolean))
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
        Query.Where(type: .value(key: lhs, op: .equals, value: rhs.value), boolean: .and)
    }

    public static func != (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .notEqualTo, value: rhs.value), boolean: .and)
    }

    public static func < (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .lessThan, value: rhs.value), boolean: .and)
    }

    public static func > (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .greaterThan, value: rhs.value), boolean: .and)
    }

    public static func <= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .lessThanOrEqualTo, value: rhs.value), boolean: .and)
    }

    public static func >= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .greaterThanOrEqualTo, value: rhs.value), boolean: .and)
    }

    public static func ~= (lhs: String, rhs: SQLValueConvertible) -> Query.Where {
        Query.Where(type: .value(key: lhs, op: .like, value: rhs.value), boolean: .and)
    }
}

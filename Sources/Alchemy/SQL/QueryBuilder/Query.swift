import Foundation
import NIO

public class Query: Sequelizable {
    public enum LockStrength: String {
        case update = "FOR UPDATE", share = "FOR SHARE"
    }

    public enum LockOption: String {
        case noWait = "NO WAIT", skipLocked = "SKIP LOCKED"
    }

    let database: DatabaseDriver
    
    private(set) var columns: [SQL] = [SQL("*")]
    private(set) var from: String?
    private(set) var joins: [JoinClause]? = nil
    private(set) var wheres: [WhereClause] = []
    private(set) var groups: [String] = []
    private(set) var havings: [WhereClause] = []
    private(set) var orders: [OrderClause] = []
    private(set) var limit: Int? = nil
    private(set) var offset: Int? = nil
    private(set) var isDistinct = false
    private(set) var lock: String? = nil

    public init(database: DatabaseDriver) {
        self.database = database
    }

    /// Get the raw `SQL` for a given query.
    ///
    /// - Returns: A `SQL` value wrapper containing the executable
    ///   query and bindings.
    public func toSQL() -> SQL {
        return (try? self.database.grammar.compileSelect(query: self))
            ?? SQL()
    }

    /// Set the columns that should be returned by the query.
    ///
    /// - Parameters:
    ///   - columns: An array of columns to be returned by the query.
    ///     Defaults to `[*]`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    @discardableResult
    public func select(_ columns: [Column] = ["*"]) -> Self {
        self.columns = columns.map(\.columnSQL)
        return self
    }

    /// Set the table to perform a query from.
    ///
    /// - Parameters:
    ///   - table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func table(_ table: String) -> Self {
        self.from = table
        return self
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
    public func from(_ table: String, as alias: String? = nil) -> Self {
        guard let alias = alias else {
            return self.table(table)
        }
        return self.table("\(table) as \(alias)")
    }

    /// Join data from a separate table into the current query data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    ///   - type: The `JoinType` of the sql join. Defaults to
    ///     `.inner`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func join(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String,
        type: JoinType = .inner
    ) -> Self {
        let join = JoinClause(database: self.database, type: type, table: table)
            .on(first: first, op: op, second: second)
        if joins == nil {
            joins = [join]
        }
        else {
            joins?.append(join)
        }
        return self
    }

    /// Left join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func leftJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .left
        )
    }

    /// Right join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func rightJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .right
        )
    }

    /// Cross join data from a separate table into the current query
    /// data.
    ///
    /// - Parameters:
    ///   - table: The table to be joined.
    ///   - first: The column from the current query to be matched.
    ///   - op: The `Operator` to be used in the comparison. Defaults
    ///     to `.equals`.
    ///   - second: The column from the joining table to be matched.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func crossJoin(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String
    ) -> Self {
        self.join(
            table: table,
            first: first,
            op: op,
            second: second,
            type: .cross
        )
    }

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
        in values: [Parameter],
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
    public func orWhere(key: String, in values: [Parameter], type: WhereIn.InType = .in) -> Self {
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
    public func whereNot(key: String, in values: [Parameter], boolean: WhereBoolean = .and) -> Self {
        return self.where(key: key, in: values, type: .notIn, boolean: boolean)
    }

    /// A helper for adding an **or** `whereNot` clause.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - values: The values that the column should not match.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orWhereNot(key: String, in values: [Parameter]) -> Self {
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
    public func whereRaw(sql: String, bindings: [Parameter], boolean: WhereBoolean = .and) -> Self {
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
    public func orWhereRaw(sql: String, bindings: [Parameter]) -> Self {
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
        self.wheres.append(WhereColumn(first: first, op: op, second: Expression(second), boolean: boolean))
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

    /// Add a having clause to filter results from aggregate
    /// functions.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(_ clause: WhereValue) -> Self {
        self.havings.append(clause)
        return self
    }

    /// An alias for `having(_ clause:) ` that appends an or clause
    /// instead of an and clause.
    ///
    /// - Parameter clause: A `WhereValue` clause matching a column to a
    ///   value.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orHaving(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        return self.having(clause)
    }

    /// Add a having clause to filter results from aggregate functions
    /// that matches a given key to a provided value.
    ///
    /// - Parameters:
    ///   - key: The column to match against.
    ///   - op: The `Operator` to be used in the comparison.
    ///   - value: The value that the column should  match.
    ///   - boolean: How the clause should be appended (`.and` or
    ///     `.or`).
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func having(key: String, op: Operator, value: Parameter, boolean: WhereBoolean = .and) -> Self {
        return self.having(WhereValue(
            key: key,
            op: op,
            value: value.value,
            boolean: boolean)
        )
    }

    /// Group returned data by a given column.
    ///
    /// - Parameter group: The table column to group data on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func groupBy(_ group: String) -> Self {
        self.groups.append(group)
        return self
    }

    /// Order the data from the query based on given clause.
    ///
    /// - Parameter order: The `OrderClause` that defines the
    ///   ordering.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(_ order: OrderClause) -> Self {
        self.orders.append(order)
        return self
    }

    /// Order the data from the query based on a column and direction.
    ///
    /// - Parameters:
    ///   - column: The column to order data by.
    ///   - direction: The `OrderClause.Sort` direction (either `.asc`
    ///     or `.desc`). Defaults to `.asc`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func orderBy(column: Column, direction: OrderClause.Sort = .asc) -> Self {
        self.orderBy(OrderClause(column: column, direction: direction))
    }

    /// Set query to only return distinct entries.
    ///
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func distinct() -> Self {
        self.isDistinct = true
        return self
    }

    /// Offset the returned results by a given amount.
    ///
    /// - Parameter value: An amount representing the offset.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func offset(_ value: Int) -> Self {
        self.offset = max(0, value)
        return self
    }

    /// Limit the returned results to a given amount.
    ///
    /// - Parameter value: An amount to cap the total result at.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func limit(_ value: Int) -> Self {
        if (value >= 0) {
            self.limit = value
        } else {
            fatalError("No negative limits allowed!")
        }
        return self
    }

    /// A helper method to be used when needing to page returned
    /// results. Internally this uses the `limit` and `offset`
    /// methods.
    ///
    /// - Note: Paging starts at index 1, not 0.
    ///
    /// - Parameters:
    ///   - page: What `page` of results to offset by.
    ///   - perPage: How many results to show on each page. Defaults
    ///     to `25`.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public func forPage(_ page: Int, perPage: Int = 25) -> Self {
        offset((page - 1) * perPage).limit(perPage)
    }

    /// Adds custom SQL to the end of a SELECT query.
    public func forLock(_ lock: LockStrength, option: LockOption? = nil) -> Self {
        let lockOptionString = option.map { " \($0.rawValue)" } ?? ""
        self.lock = lock.rawValue + lockOptionString
        return self
    }

    /// Run a select query and return the database rows.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The rows returned by the database.
    public func get(_ columns: [Column]? = nil) async throws -> [DatabaseRow] {
        if let columns = columns {
            select(columns)
        }
        
        let sql = try self.database.grammar.compileSelect(query: self)
        return try await database.runRawQuery(sql.query, values: sql.bindings)
    }

    /// Run a select query and return the first database row only row.
    ///
    /// - Note: Optional columns can be provided that override the
    ///   original select columns.
    /// - Parameter columns: The columns you would like returned.
    ///   Defaults to `nil`.
    /// - Returns: The first row in the database, if it exists.
    public func first(_ columns: [Column]? = nil) async throws -> DatabaseRow? {
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
    public func find(field: DatabaseField, columns: [Column]? = nil) async throws -> DatabaseRow? {
        wheres.append(WhereValue(key: field.column, op: .equals, value: field.value))
        return try await limit(1).get(columns).first
    }

    /// Find the total count of the rows that match the given query.
    ///
    /// - Parameters:
    ///   - column: What column to count. Defaults to `*`.
    ///   - name: The alias that can be used for renaming the returned
    ///     count.
    /// - Returns: The count returned by the database.
    public func count(column: Column = "*", as name: String? = nil) async throws -> Int {
        var query = "COUNT(\(column))"
        if let name = name {
            query += " as \(name)"
        }
        let row = try await select([query]).first()
            .unwrap(or: DatabaseError("a COUNT query didn't return any rows"))
        let column = try row.allColumns.first
            .unwrap(or: DatabaseError("a COUNT query didn't return any columns"))
        return try row.getField(column: column).int()
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
    public func insert(
        _ value: OrderedDictionary<String, Parameter>,
        returnItems: Bool = true
    ) async throws -> [DatabaseRow] {
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
    public func insert(
        _ values: [OrderedDictionary<String, Parameter>],
        returnItems: Bool = true
    ) async throws -> [DatabaseRow] {
        try await database.grammar.insert(values, query: self, returnItems: returnItems)
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
    public func update(values: [String: Parameter]) async throws {
        let sql = try database.grammar.compileUpdate(self, values: values)
        _ = try await database.runRawQuery(sql.query, values: sql.bindings)
    }

    /// Perform a deletion on all data matching the given query.
    public func delete() async throws {
        let sql = try database.grammar.compileDelete(self)
        _ = try await database.runRawQuery(sql.query, values: sql.bindings)
    }
}

extension Query {
    /// Shortcut for running a query with the given table on
    /// `Database.default`.
    ///
    /// - Parameter table: The table to run the query on.
    /// - Returns: The current query builder `Query` to chain future
    ///   queries to.
    public static func table(_ table: String) -> Query {
        Database.default.query().table(table)
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
            return Query.table(table)
        }
        return Query.table("\(table) as \(alias)")
    }
}

extension String {
    public static func == (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .equals, value: rhs.value)
    }

    public static func != (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .notEqualTo, value: rhs.value)
    }

    public static func < (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThan, value: rhs.value)
    }

    public static func > (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThan, value: rhs.value)
    }

    public static func <= (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThanOrEqualTo, value: rhs.value)
    }

    public static func >= (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThanOrEqualTo, value: rhs.value)
    }

    public static func ~= (lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .like, value: rhs.value)
    }
}

import Foundation
import NIO

public class Query: Sequelizable {
    let database: Database
    
    private(set) var columns: [Raw] = []
    private(set) var from: String?
    private(set) var joins: [JoinClause]? = nil
    private(set) var wheres: [WhereClause] = []
    private(set) var groups: [String] = []
    private(set) var havings: [WhereClause] = []
    private(set) var orders: [OrderClause] = []
    private(set) var limit: Int? = nil
    private(set) var offset: Int? = nil

    private(set) var _distinct = false

    public init(database: Database) {
        self.database = database
    }

    public func toSQL() -> SQL {
        return (try? self.database.grammar.compileSelect(query: self))
            ?? SQL()
    }

    @discardableResult
    public func select(_ columns: [Column] = ["*"]) -> Self {

        self.columns = []
        for column in columns {
            if let column = column as? String {
                self.columns.append(Raw(column))
            }
            else if let column = column as? Raw {
                self.columns.append(column)
            }
            else {
                // Need to check if queryable & closures
            }
        }
        return self
    }

    /// Set the table to perform a query from.
    ///
    /// - Parameters:
    ///   - table: The table to run the query on
    /// - Returns: The current query builder `Query` to chain future queries to
    public func table(_ table: String) -> Self {
        self.from = table
        return self
    }

    /// An alias for `table(_ table: String)` to be used when running
    /// a `select` query that also lets you alias the table name.
    ///
    /// - Parameters:
    ///   - table: The table to select data from
    ///   - alias: An optional alias to use in place of table name
    /// - Returns: The current query builder `Query` to chain future queries to
    public func from(table: String, as alias: String? = nil) -> Self {
        guard let alias = alias else {
            return self.table(table)
        }
        return self.table("\(table) as \(alias)")
    }

    /// Join data from a separate table into the current query.
    ///
    /// - Parameters:
    ///   - table: The table to be joined
    ///   - first: The column from the current query to be matched
    ///   - op: The `Operator` to be used in the comparison
    ///   - second: The column from the joining table to be matched
    ///   - type: The `JoinType` of the sql join
    /// - Returns: The current query builder `Query` to chain future queries to
    public func join(
        table: String,
        first: String,
        op: Operator = .equals,
        second: String,
        type: JoinType = .inner
    ) -> Self {
        let join = JoinClause(query: self, type: type, table: table)
            .on(first: first, op: op, second: second)
        if joins == nil {
            joins = [join]
        }
        else {
            joins?.append(join)
        }
        return self
    }

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
    ///   - clause: A `WhereValue` clause matching a column to a given value.
    /// - Returns: The current query builder `Query` to chain future queries to
    public func `where`(_ clause: WhereValue) -> Self {
        self.wheres.append(clause)
        return self
    }

    /// An alias for `where(_ clause: WhereValue) ` that appends an or
    /// query instead of an and query.
    ///
    /// - Parameters:
    ///   - clause: A `WhereValue` clause matching a column to a given value.
    /// - Returns: The current query builder `Query` to chain future queries to
    public func orWhere(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        return self.where(clause)
    }

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

    public func orWhere(key: String, in values: [Parameter], type: WhereIn.InType = .in) -> Self {
        return self.where(
            key: key,
            in: values,
            type: type,
            boolean: .or
        )
    }

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

    public func orWhere(_ closure: @escaping WhereNestedClosure) -> Self {
        return self.where(closure, boolean: .or)
    }

    public func whereNot(key: String, in values: [Parameter], boolean: WhereBoolean = .and) -> Self {
        return self.where(key: key, in: values, type: .notIn, boolean: boolean)
    }

    public func orWhereNot(key: String, in values: [Parameter]) -> Self {
        return self.where(key: key, in: values, type: .notIn, boolean: .or)
    }

    public func whereRaw(sql: String, bindings: [Parameter], boolean: WhereBoolean = .and) -> Self {
        self.wheres.append(WhereRaw(
            query: sql,
            values: bindings.map { $0.value },
            boolean: boolean)
        )
        return self
    }

    public func orWhereRaw(sql: String, bindings: [Parameter]) -> Self {
        return self.whereRaw(sql: sql, bindings: bindings, boolean: .or)
    }

    public func whereColumn(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> Self {
        self.wheres.append(WhereColumn(first: first, op: op, second: Expression(second), boolean: boolean))
        return self
    }

    public func orWhereColumn(first: String, op: Operator, second: String) -> Self {
        return self.whereColumn(first: first, op: op, second: second, boolean: = .or)
    }

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

    public func orWhereNull(key: String) -> Self {
        return self.whereNull(key: key, boolean: .or)
    }

    public func whereNotNull(key: String, boolean: WhereBoolean = .and) -> Self {
        return self.whereNull(key: key, boolean: boolean, not: true)
    }

    public func orWhereNotNull(key: String) -> Self {
        return self.whereNotNull(key: key, boolean: .or)
    }


    public func having(_ clause: WhereValue) -> Self {
        self.havings.append(clause)
        return self
    }

    public func orHaving(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        return self.having(clause)
    }

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
    /// - Parameters:
    ///   - group: The table column to group data on
    /// - Returns: The current query builder `Query` to chain future queries to
    public func groupBy(_ group: String) -> Self {
        self.groups.append(group)
        return self
    }

    /// Order the data from the query based on given clause.
    ///
    /// - Parameters:
    ///   - order: The `OrderClause` that defines the ordering
    /// - Returns: The current query builder `Query` to chain future queries to
    public func orderBy(_ order: OrderClause) -> Self {
        self.orders.append(order)
        return self
    }

    /// Order the data from the query based on a column and direction.
    ///
    /// - Parameters:
    ///   - column: The column to order data by
    ///   - direction: The `OrderClause.Sort` direction (either `asc` or `desc`)
    /// - Returns: The current query builder `Query` to chain future queries to
    public func orderBy(column: Column, direction: OrderClause.Sort = .asc) -> Self {
        return self.orderBy(OrderClause(column: column, direction: direction))
    }

    public func distinct() -> Self {
        self._distinct = true
        return self
    }

    /// Offset the returned results by a given amount.
    ///
    /// - Parameters:
    ///   - value: An amount representing the offset.
    /// - Returns: The current query builder `Query` to chain future queries to
    public func offset(_ value: Int) -> Self {
        self.offset = max(0, value)
        return self
    }

    /// Limit the returned results to a given amount.
    ///
    /// - Parameters:
    ///   - value: An amount to cap the total result at.
    /// - Returns: The current query builder `Query` to chain future queries to
    public func limit(_ value: Int) -> Self {
        if (value >= 0) {
            self.limit = value
        } else {
            fatalError("No negative limits allowed!")
        }
        return self
    }

    /// A helper method to be used when needing to page returned results.
    /// Internally this uses the `limit` and `offset` methods.
    ///
    /// Note: Paging starts at index 1, not zero
    ///
    /// - Parameters:
    ///   - page: What `page` of results to offset by
    ///   - perPage: How many results to show on each page
    /// - Returns: The current query builder `Query` to chain future queries to
    public func forPage(_ page: Int, perPage: Int = 25) -> Self {
        return offset((page - 1) * perPage).limit(perPage)
    }

    public func get(_ columns: [Column]? = nil) -> EventLoopFuture<[DatabaseRow]> {
        if let columns = columns {
            self.select(columns)
        }
        do {
            let sql = try self.database.grammar.compileSelect(query: self)
            return self.database.runRawQuery(sql.query, values: sql.bindings)
        }
        catch let error {
            return .new(error: error)
        }
    }

    public func first(_ columns: [Column]? = nil) -> EventLoopFuture<DatabaseRow?> {
        return self.limit(1)
            .get(columns)
            .map { $0.first }
    }

    public func find(field: DatabaseField, columns: [Column]? = nil) -> EventLoopFuture<DatabaseRow?> {
        self.wheres.append(WhereValue(key: field.column, op: .equals, value: field.value))
        return self.limit(1)
            .get(columns)
            .map { $0.first }
    }

    public func count(column: Column = "*", as name: String? = nil) -> EventLoopFuture<Int?> {
        var query = "COUNT(\(column))"
        if let name = name {
            query += " as \(name)"
        }
        return self.select([query])
            .first()
            .flatMapThrowing {
                if let column = $0?.allColumns.first {
                    return try $0?.getField(column: column).int()
                }
                return nil
        }
    }

    public func insert(_ value: OrderedDictionary<String, Parameter>) -> EventLoopFuture<[DatabaseRow]> {
        return insert([value])
    }

    public func insert(_ values: [OrderedDictionary<String, Parameter>]) -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try self.database.grammar.compileInsert(self, values: values)
            return self.database.runRawQuery(sql.query, values: sql.bindings)
        }
        catch let error {
            return .new(error: error)
        }
    }

    public func update(values: [String: Parameter]) throws -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try self.database.grammar.compileUpdate(self, values: values)
            return self.database.runRawQuery(sql.query, values: sql.bindings)
        }
        catch let error {
            return .new(error: error)
        }
    }

    
    public func delete() -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try self.database.grammar.compileDelete(self)
            return self.database.runRawQuery(sql.query, values: sql.bindings)
        }
        catch let error {
            return .new(error: error)
        }
    }
}


extension String {
    public static func ==(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .equals, value: rhs.value)
    }

    public static func !=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .notEqualTo, value: rhs.value)
    }

    public static func <(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThan, value: rhs.value)
    }

    public static func >(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThan, value: rhs.value)
    }

    public static func <=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .lessThanOrEqualTo, value: rhs.value)
    }

    public static func >=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .greaterThanOrEqualTo, value: rhs.value)
    }

    public static func ~=(lhs: String, rhs: Parameter) -> WhereValue {
        return WhereValue(key: lhs, op: .like, value: rhs.value)
    }
}

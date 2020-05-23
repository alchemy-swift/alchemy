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
        return (try? database.grammar.compileSelect(query: self))
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

    public func from(table: String, as alias: String? = nil) -> Self {

        //TODO: Allow for selecting from subqueries

        guard let alias = alias else {
            self.from = table
            return self
        }
        self.from = "\(table) as \(alias)"
        return self
    }

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

    public func `where`(_ clause: WhereValue) -> Self {
        self.wheres.append(clause)
        return self
    }

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

    @discardableResult
    public func whereColumn(first: String, op: Operator, second: String, boolean: WhereBoolean = .and) -> Self {
        self.wheres.append(WhereColumn(first: first, op: op, second: Expression(second), boolean: boolean))
        return self
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

    public func groupBy(_ group: String) -> Self {
        self.groups.append(group)
        return self
    }

    public func orderBy(_ order: OrderClause) -> Self {
        self.orders.append(order)
        return self
    }

    public func orderBy(column: Column, direction: OrderClause.Sort = .asc) -> Self {
        //TODO: Add support for sort subquery
        return self.orderBy(OrderClause(column: column, direction: direction))
    }

    public func distinct() -> Self {
        self._distinct = true
        return self
    }



    public func offset(_ value: Int) -> Self {
        self.offset = max(0, value)
        return self
    }

    public func limit(_ value: Int) -> Self {
        if (value >= 0) {
            self.limit = value
        }
        return self
    }

    // Paging starts at index 1, not zero
    public func forPage(page: Int, perPage: Int = 25) -> Self {
        return offset((page - 1) * perPage).limit(perPage)
    }

    public func get(_ columns: [Column]? = nil, on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        if let columns = columns {
            self.select(columns)
        }
        do {
            let sql = try database.grammar.compileSelect(query: self)
            return self.database.runQuery(sql.query, values: sql.bindings, on: loop)
        }
        catch let error {
            return loop.makeFailedFuture(error)
        }
    }

    public func first(_ columns: [Column]? = nil, on loop: EventLoop = Loop.current) -> EventLoopFuture<DatabaseRow?> {
        return self.limit(1)
            .get(columns, on: loop)
            .flatMapThrowing { $0.first }
    }

    public func find(field: DatabaseField, columns: [Column]? = nil, on loop: EventLoop = Loop.current) -> EventLoopFuture<DatabaseRow?> {
        self.wheres.append(WhereValue(key: field.column, op: .equals, value: field.value))
        return self.limit(1)
            .get(columns, on: loop)
            .flatMapThrowing { $0.first }
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
                    return try $0?.getField(columnName: column).int()
                }
                return nil
        }
    }

    //
    //    paginate(perPage, columns, page)
    //    exists()
    //

    public func insert(_ value: KeyValuePairs<String, Parameter>, on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        return insert([value])
    }

    public func insert(_ values: [KeyValuePairs<String, Parameter>], on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try database.grammar.compileInsert(self, values: values)
            return self.database.runQuery(sql.query, values: sql.bindings, on: loop)
        }
        catch let error {
            return loop.makeFailedFuture(error)
        }
    }

    public func update(values: [String: Parameter], on loop: EventLoop = Loop.current) throws -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try database.grammar.compileUpdate(self, values: values)
            return self.database.runQuery(sql.query, values: sql.bindings, on: loop)
        }
        catch let error {
            return loop.makeFailedFuture(error)
        }
    }

    public func delete(on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try database.grammar.compileDelete(self)
            return self.database.runQuery(sql.query, values: sql.bindings, on: loop)
        }
        catch let error {
            return loop.makeFailedFuture(error)
        }
    }

    //    updateOrInsert()
    //    delete(id = null)
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

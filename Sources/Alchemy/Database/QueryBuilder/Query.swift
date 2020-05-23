import Foundation
import NIO

public class Query {

    let database: Database

    var columns: [String]? = nil
    private(set) var from: String?
    private(set) var joins: [JoinClause]? = nil
    private(set) var wheres: [WhereClause] = []
    private(set) var groups: [String] = []
    private(set) var havings: [Any] = []
    private(set) var orders: [OrderClause] = []
    private(set) var limit: Int? = nil
    private(set) var offset: Int? = nil

    public var distinct = false

    init(database: Database) {
        self.database = database
    }

    public func toSQL() -> SQL {
        return database.grammar.compileSelect(query: self)
    }

    func isQueryable(column: Any) -> Bool {
        return false
    }

    public func select(_ columns: [Any] = ["*"]) -> Self {

        self.columns = []
        for column in columns {

            if let column = column as? String {
                self.columns?.append(column)
            }
            else {
                // Need to check if queryable & closures
            }
        }
        return self
    }

    //    func selectRaw(expression, array bindings)
    //
    //    func selectRaw(var expression, bindings) {
    //
    //    }

    public func from(table: String, as alias: String? = nil) -> Self {

        //TODO: Something about subquery

        guard let alias = alias else {
            self.from = table
            return self
        }
        self.from = "\(table) as \(alias)"
        return self
    }

    //    join(table, first, operator, second, type, where)
    //    leftJoin(table, first, operator, second)
    //    rightJoin(table, first, operator, second)
    //    crossJoin(table, first, operator, second)

    public func `where`(_ clause: WhereValue) -> Self {
        self.wheres.append(clause)
        return self
    }

    public func orWhere(_ clause: WhereValue) -> Self {
        var clause = clause
        clause.boolean = .or
        self.wheres.append(clause)
        return self
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

    //    whereNull(column, boolean = "and", not = false)
    //    orWhereNull(column) = whereNull(column, "or")
    //    whereNotNull(column, boolean = "and") = whereNull(column, boolean, true)
    //    having(column, operator, value, boolean = "and")
    //    orHaving(column, operator, value) = having(column, operator, value, "or")

    public func groupBy(_ group: String) -> Self {
        self.groups.append(group)
        return self
    }

    public func orderBy(_ order: OrderClause) -> Self {
        self.orders.append(order)
        return self
    }

    public func orderBy(column: String, direction: OrderClause.Sort = .asc) -> Self {
        //TODO: Add support for sort subquery
        return self.orderBy(OrderClause(column: column, direction: direction))
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

    public func get(_ columns: [Any] = ["*"], on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        let sql = database.grammar.compileSelect(query: self)
        return self.database.query(sql.query, values: sql.bindings, on: loop)
    }

    public func first(_ columns: [Any] = ["*"], on loop: EventLoop = Loop.current) -> EventLoopFuture<DatabaseRow?> {
        return self.limit(1)
            .get(columns, on: loop)
            .flatMapThrowing { $0.first }
    }

    public func find(field: DatabaseField, columns: [Any] = ["*"], on loop: EventLoop = Loop.current) -> EventLoopFuture<DatabaseRow?> {
        self.wheres.append(WhereValue(key: field.column, op: .equals, value: field.value))
        return self.limit(1)
            .get(columns, on: loop)
            .flatMapThrowing { $0.first }
    }

    //
    //    paginate(perPage, columns, page)
    //    count()
    //    exists()
    //

    public func insert(_ value: KeyValuePairs<String, Parameter>, on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        return insert([value])
    }

    public func insert(_ values: [KeyValuePairs<String, Parameter>], on loop: EventLoop = Loop.current) -> EventLoopFuture<[DatabaseRow]> {
        do {
            let sql = try database.grammar.compileInsert(self, values: values)
            return self.database.query(sql.query, values: sql.bindings, on: loop)
        }
        catch let error {
            return loop.makeFailedFuture(error)
        }
    }

    public func update(values: [String: Parameter], on loop: EventLoop = Loop.current) throws -> EventLoopFuture<[DatabaseRow]> {
        let sql = try database.grammar.compileUpdate(self, values: values)
        return self.database.query(sql.query, values: sql.bindings, on: loop)
    }

    public func delete(on loop: EventLoop = Loop.current) throws -> EventLoopFuture<[DatabaseRow]> {
        let sql = try database.grammar.compileDelete(self)
        return self.database.query(sql.query, values: sql.bindings, on: loop)
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

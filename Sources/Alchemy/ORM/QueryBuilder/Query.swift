import Foundation

public class Query {

    let database: Database

    var columns: [String]? = nil
    private(set) var from: String?
    private(set) var joins: [JoinClause]? = nil
    private(set) var wheres: [WhereClause] = []
    private(set) var groups: [String] = []
    private(set) var havings: [Any] = []
    private(set) var orders: [Order] = []
    private(set) var limit: Int? = nil
    private(set) var offset: Int = 0

    public var distinct = false

    init(database: Database) {
        self.database = database
    }

    public func toSQL() -> String {
        return database.grammar.compileSelect(query: self)
    }

    func isQueryable(column: Any) -> Bool {
        return false
    }

    public func select(_ columns: [Any] = ["*"]) -> Query {

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

    public func from(table: ModelTable) -> Query {
        return from(table: table.name)
    }

    public func from(table: String, as alias: String? = nil) -> Query {

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
    //    func filter(column: String, operator: Operator, value: String, boolean: String? = "and") {
    //
    //    }

    public func filter(_ clause: WhereClause) -> Query {
        self.wheres.append(clause)
        return self
    }
    //    orWhere(column, operator, value) = where(column, operator, value, "or")
    //    whereRaw(sql, bindings, boolean = "and")
    //    orWhereRaw(sql, bindings)
    //    whereIn(column, values, boolean, not = false)
    //    orWhereIn(column, values, boolean)
    //    whereNotIn(column, values, boolean = "and")
    //    orWhereNotIn(column, values)
    //    whereNull(column, boolean = "and", not = false)
    //    orWhereNull(column) = whereNull(column, "or")
    //    whereNotNull(column, boolean = "and") = whereNull(column, boolean, true)
    //    groupBy(groups)
    //    having(column, operator, value, boolean = "and")
    //    orHaving(column, operator, value) = having(column, operator, value, "or")

    @discardableResult
    public func whereColumn(first: String, op: String, second: String, boolean: String = "and") -> Query {
        self.wheres.append(WhereClause(first: first, op: op, second: second, boolean: boolean))
        return self
    }


    public func orderBy(column: String, direction: Order.Sort = .ascending) -> Query {
        //TODO: Add support for sort subquery
        return self.orderBy(Order(column: column, direction: direction))
    }

    public func orderBy(_ order: Order) -> Query {
        return self
    }

    public func offset(_ value: Int) -> Query {
        self.offset = max(0, value)
        return self
    }

    public func limit(_ value: Int) -> Query {
        if (value >= 0) {
            self.limit = value
        }
        return self
    }

    public func forPage(page: Int, perPage: Int = 25) -> Query {
        return offset((page - 1) * perPage).limit(perPage)
    }

//    public func get($columns = ["*"])
//    {
//        return collect($this->onceWithColumns(Arr::wrap($columns), function () {
//            return $this->processor->processSelect($this, $this->runSelect());
//        }));
//    }
    //
//    func first(_ columns: [String]) {
//
//    }
    //
    //    private func onceWithColumns($columns, $callback)
    //    {
    //        let original = self.columns
    //        if original.isEmpty {
    //            self.columns = columns
    //        }
    //
    //        let result =
    //
    //        if (is_null($original)) {
    //            $this->columns = $columns;
    //        }
    //
    //        $result = $callback();
    //
    //        $this->columns = $original;
    //
    //        return $result;
    //    }


    // Query for a single record by ID
    //    func find(id: Identifier, columns = ["*"]) -> Builder {
    //        return `where`(column: "id", operator: <#T##<<error type>>#>, value: <#T##String#>)
    //    }

    //    get(columns = ["*"])
    //    paginate(perPage, columns, page)
    //    count()
    //    exists()
    //
    //    insert(values)
    //    update(values)
    //    updateOrInsert()
    //    delete(id = null)
    //
    //
    //
    //    //Model methods:
    //    refresh()
    //    save()
    //    chunk(count, callback)
    //    firstOrNew(conditions, values)
    //    with(relationships)
}


extension String {
    public static func ==(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "=", value: rhs)
    }

    public static func !=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "!=", value: rhs)
    }

    public static func <(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "<", value: rhs)
    }

    public static func >(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: ">", value: rhs)
    }

    public static func <=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "<=", value: rhs)
    }

    public static func >=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: ">=", value: rhs)
    }

    public static func ~=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "LIKE", value: rhs)
    }
}

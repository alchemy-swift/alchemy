
class Connection {
    var grammar = Grammar()
}
class Join {}
class Identifier {}

struct Future<T> {
    init(_ val: T) {

     }
}

protocol Model {
    static var table: String { get }
    static func query() -> Query
}

extension Model {
    static func query() -> Query {
        return Query(connection: Connection()).from(table: self.table)
    }
}



class Grammar {
    
    private let selectComponents: [AnyKeyPath] = [
        \Query.columns,
        \Query.from,
        \Query.joins,
        \Query.wheres,
        \Query.groups,
        \Query.havings,
        \Query.orders,
        \Query.limit,
        \Query.offset
    ]
    
    func compileSelect(query: Query) -> String {

        // If the query does not have any columns set, we"ll set the columns to the
        // * character to just get all of the columns from the database. Then we
        // can build the query and concatenate all the pieces together as one.
        let original = query.columns
        
        if query.columns == nil {
            query.columns = ["*"]
        }
        
        // To compile the query, we"ll spin through each component of the query and
        // see if that component exists. If it does we"ll just call the compiler
        // function for the component which is responsible for making the SQL.
        let sql = concatenate(compileComponents(query: query))

        query.columns = original;

        return sql
    }
    
    private func compileComponents(query: Query) -> [String]
    {
        var sql: [String] = [];
        for component in selectComponents {
            // To compile the query, we"ll spin through each component of the query and
            // see if that component exists. If it does we"ll just call the compiler
            // function for the component which is responsible for making the SQL.
            if let part = query[keyPath: component] {
                if component == \Query.columns, let columns = part as? [String] {
                    sql.append(compileColumns(query, columns: columns))
                }
                else if component == \Query.from, let table = part as? String {
                    sql.append(compileFrom(query, table: table))
                }
                else if component == \Query.wheres {
                    sql.append(compileWheres(query))
                }
            }
        }
        return sql
    }
    
    private func compileColumns(_ query: Query, columns: [String]) -> String
    {
        let select = query.distinct ? "select distinct" : "select"
        return "\(select) \(columns.joined(separator: ", "))"
    }
    
    private func compileFrom(_ query: Query, table: String) -> String
    {
        return "from \(table)"
    }
    
    private func compileWheres(_ query: Query) -> String
    {

        // If we actually have some where clauses, we will strip off the first boolean
        // operator, which is added by the query builders for convenience so we can
        // avoid checking for the first clauses in each of the compilers methods.
        
        // Need to handle nested stuff somehow
        var parts = query.wheres.map { "\($0.boolean) \($0.key) \($0.op) \($0.value)" }
        if (parts.count > 0) {
            return removeLeadingBoolean(parts.joined(separator: " "))
        }
        return ""
    }
    
    private func removeLeadingBoolean(_ value: String) -> String
    {
        if value.hasPrefix("and ") {
            return String(value.dropFirst(4))
        }
        else if value.hasPrefix("or ") {
            return String(value.dropFirst(3))
        }
        return value
    }
    
    private func concatenate(_ segments: [String]) -> String
    {
        return segments.filter { !$0.isEmpty }.joined(separator: " ")
    }
}




struct Order {
    
    enum Sort: String {
        case ascending = "asc"
        case descending = "desc"
    }
    
    let column: String
    let direction: Sort
}

struct WhereClause {
    let key: String
    let op: String
    let value: String
    let boolean: String
    
    init(key: String, op: String, value: String, boolean: String = "and") {
        self.key = key
        self.op = op
        self.value = value
        self.boolean = boolean
    }
    
    let operators = [
        "=", "<", ">", "<=", ">=", "<>", "!=", "<=>",
        "like", "like binary", "not like", "ilike",
        "&", "|", "^", "<<", ">>",
        "rlike", "not rlike", "regexp", "not regexp",
        "~", "~*", "!~", "!~*", "similar to",
        "not similar to", "not ilike", "~~*", "!~~*",
    ];
}

class Query {
    
    let connection: Connection
    
    fileprivate var columns: [String]? = nil
    fileprivate var from: String?
    fileprivate var joins: [Join]? = nil
    fileprivate var wheres: [WhereClause] = []
    fileprivate var groups: [String] = []
    fileprivate var havings: [Any] = []
    fileprivate var orders: [Order] = []
    fileprivate var limit: Int? = nil
    fileprivate var offset: Int = 0
    
    public var distinct = false
    
    init(connection: Connection) {
        self.connection = connection
    }
    
    func toSQL() -> String {
        return self.connection.grammar.compileSelect(query: self)
    }
    
    func isQueryable(column: Any) -> Bool {
        return false
    }
    
    func select(_ columns: [Any] = ["*"]) -> Query {
        
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
    
    func from(table: String, as alias: String? = nil) -> Query {
        
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
    
    func filter(_ clause: WhereClause) -> Query {
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
    
    func orderBy(column: String, direction: Order.Sort = .ascending) -> Query {
        //TODO: Add support for sort subquery
        return self.orderBy(Order(column: column, direction: direction))
    }
    
    func orderBy(_ order: Order) -> Query {
        return self
    }
    
    func offset(_ value: Int) -> Query {
        self.offset = max(0, value)
        return self
    }
    
    func limit(_ value: Int) -> Query {
        if (value >= 0) {
            self.limit = value
        }
        return self
    }
    
    func forPage(page: Int, perPage: Int = 25) -> Query {
        return offset((page - 1) * perPage).limit(perPage)
    }
//
//    public function get($columns = ["*"])
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
    static func ==(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "=", value: rhs)
    }
    
    static func !=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "!=", value: rhs)
    }
    
    static func <(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "<", value: rhs)
    }
    
    static func >(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: ">", value: rhs)
    }
    
    static func <=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "<=", value: rhs)
    }
    
    static func >=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: ">=", value: rhs)
    }
    
    static func ~=(lhs: String, rhs: String) -> WhereClause {
        return WhereClause(key: lhs, op: "LIKE", value: rhs)
    }
}


struct User: Model, Codable {
    
    static var table = "user"
    
    var firstName: String
    var lastName: String
}

let query = User.query()
    .select(["first_name", "last_name"])
    .filter("last_name" == "Anderson")
    .filter("first_name" ~= "Chris%")


print(query.toSQL())

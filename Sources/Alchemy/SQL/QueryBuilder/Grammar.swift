import Foundation

/// Used for compiling query builders into raw SQL statements.
open class Grammar {
    struct GrammarError: Error {
        let message: String
        static let missingTable = GrammarError(message: "Missing a table to run the query on.")
    }

    // MARK: Compiling Query Builders
    
    open func compileSelect(query: Query) throws -> SQL {
        let parts: [SQL?] = [
            self.compileColumns(query, columns: query.columns),
            try self.compileFrom(query, table: query.from),
            self.compileJoins(query, joins: query.joins),
            self.compileWheres(query),
            self.compileGroups(query, groups: query.groups),
            self.compileHavings(query),
            self.compileOrders(query, orders: query.orders),
            self.compileLimit(query, limit: query.limit),
            self.compileOffset(query, offset: query.offset)
        ]

        let (sql, bindings) = QueryHelpers.groupSQL(values: parts)
        return SQL(sql.joined(separator: " "), bindings: bindings)
    }

    open func compileJoins(_ query: Query, joins: [JoinClause]?) -> SQL? {
        guard let joins = joins else { return nil }
        var bindings: [DatabaseValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join) else {
                return nil
            }
            bindings += whereSQL.bindings
            if let nestedJoins = join.joins,
                let nestedSQL = compileJoins(query, joins: nestedJoins) {
                bindings += nestedSQL.bindings
                return self.trim("\(join.type) join (\(join.table)\(nestedSQL.query)) \(whereSQL.query)")
            }
            return self.trim("\(join.type) join \(join.table) \(whereSQL.query)")
        }.joined(separator: " ")
        return SQL(query, bindings: bindings)
    }

    open func compileGroups(_ query: Query, groups: [String]) -> SQL? {
        if groups.isEmpty { return nil }
        return SQL("group by \(groups.joined(separator: ", "))")
    }

    open func compileHavings(_ query: Query) -> SQL? {
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.havings)
        if (sql.count > 0) {
            let clauses = QueryHelpers.removeLeadingBoolean(
                sql.joined(separator: " ")
            )
            return SQL("having \(clauses)", bindings: bindings)
        }
        return nil
    }

    open func compileOrders(_ query: Query, orders: [OrderClause]) -> SQL? {
        if orders.isEmpty { return nil }
        let ordersSQL = orders.map { $0.toSQL().query }.joined(separator: ", ")
        return SQL("order by \(ordersSQL)")
    }

    open func compileLimit(_ query: Query, limit: Int?) -> SQL? {
        guard let limit = limit else { return nil }
        return SQL("limit \(limit)")
    }

    open func compileOffset(_ query: Query, offset: Int?) -> SQL? {
        guard let offset = offset else { return nil }
        return SQL("offset \(offset)")
    }

    open func compileInsert(_ query: Query, values: [OrderedDictionary<String, Parameter>]) throws -> SQL {
        
        guard let table = query.from else { throw GrammarError.missingTable }

        if values.isEmpty {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].map { $0.key }.joined(separator: ", ")
        var parameters: [DatabaseValue] = []
        var placeholders: [String] = []

        for value in values {
            parameters.append(contentsOf: value.map { $0.value.value })
            placeholders.append("(\(parameterize(value.map { $0.value })))")
        }
        return SQL(
            "insert into \(table) (\(columns)) values \(placeholders.joined(separator: ", "))",
            bindings: parameters
        )
    }
    
    open func insert(_ values: [OrderedDictionary<String, Parameter>], query: Query, returnItems: Bool)
        -> EventLoopFuture<[DatabaseRow]>
    {
        catchError {
            let sql = try self.compileInsert(query, values: values)
            return query.database.runRawQuery(sql.query, values: sql.bindings)
        }
    }
    
    open func compileUpdate(_ query: Query, values: [String: Parameter]) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        var bindings: [DatabaseValue] = []
        let columnSQL = compileUpdateColumns(query, values: values)

        var base = "update \(table)"
        if let clauses = query.joins,
            let joinSQL = compileJoins(query, joins: clauses) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " set \(columnSQL.query)"

        if let whereSQL = compileWheres(query) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.query)"
        }
        return SQL(base, bindings: bindings)
    }

    open func compileUpdateColumns(_ query: Query, values: [String: Parameter]) -> SQL {
        var bindings: [DatabaseValue] = []
        var parts: [String] = []
        for value in values {
            if let expression = value.value as? Expression {
                parts.append("\(value.key) = \(expression.description)")
            }
            else {
                bindings.append(value.value.value)
                parts.append("\(value.key) = ?")
            }
        }

        return SQL(parts.joined(separator: ", "), bindings: bindings)
    }

    open func compileDelete(_ query: Query) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        if let whereSQL = compileWheres(query) {
            return SQL("delete from \(table) \(whereSQL.query)", bindings: whereSQL.bindings)
        }
        else {
            return SQL("delete from \(table)")
        }
    }
    
    // MARK: - Compiling Migrations
    
    open func compileCreate(table: String, ifNotExists: Bool, columns: [CreateColumn]) -> SQL {
        var columnStrings: [String] = []
        var constraintStrings: [String] = []
        for (column, constraints) in columns.map({ $0.sqlString(with: self) }) {
            columnStrings.append(column)
            constraintStrings.append(contentsOf: constraints)
        }
        return SQL(
            """
            CREATE TABLE\(ifNotExists ? " IF NOT EXISTS" : "") \(table) (
                \((columnStrings + constraintStrings).joined(separator: ",\n    "))
            )
            """
        )
    }
    
    open func compileRename(table: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME TO \(to)")
    }
    
    open func compileDrop(table: String) -> SQL {
        SQL("DROP TABLE \(table)")
    }
    
    open func compileAlter(table: String, dropColumns: [String], addColumns: [CreateColumn]) -> [SQL] {
        guard !dropColumns.isEmpty || !addColumns.isEmpty else {
            return []
        }
        
        var adds: [String] = []
        var constraints: [String] = []
        for (sql, tableConstraints) in addColumns.map({ $0.sqlString(with: self) }) {
            adds.append("ADD COLUMN \(sql)")
            constraints.append(contentsOf: tableConstraints.map { "ADD \($0)" })
        }
        
        let drops = dropColumns.map { "DROP COLUMN \($0)" }
        return [
            SQL("""
                ALTER TABLE \(table)
                    \((adds + drops + constraints).joined(separator: ",\n    "))
                """)]
    }
    
    open func compileRenameColumn(table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column) TO \(to)")
    }
    
    open func compileCreateIndexes(table: String, indexes: [CreateIndex]) -> [SQL] {
        indexes.map { SQL($0.toSQL(table: table)) }
    }
    
    open func compileDropIndex(table: String, indexName: String) -> SQL {
        SQL("DROP INDEX \(indexName)")
    }
    
    open func typeString(for type: ColumnType) -> String {
        switch type {
        case .bool:
            return "bool"
        case .date:
            return "timestamptz"
        case .double:
            return "float8"
        case .increments:
            return "serial"
        case .int:
            return "int"
        case .bigInt:
            return "bigint"
        case .json:
            return "json"
        case .string(let length):
            switch length {
            case .unlimited:
                return "text"
            case .limit(let characters):
                return "varchar(\(characters))"
            }
        case .uuid:
            return "uuid"
        }
    }
    
    open func jsonLiteral(from jsonString: String) -> String {
        "'\(jsonString)'::jsonb"
    }
    
    open func allowsUnsigned() -> Bool {
        false
    }

    private func parameterize(_ values: [Parameter]) -> String {
        return values.map { parameter($0) }.joined(separator: ", ")
    }

    private func parameter(_ value: Parameter) -> String {
        if let value = value as? Expression {
            return value.description
        }
        return "?"
    }

    private func trim(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func compileWheres(_ query: Query) -> SQL? {
        // If we actually have some where clauses, we will strip off
        // the first boolean operator, which is added by the query
        // builders for convenience so we can avoid checking for
        // the first clauses in each of the compilers methods.

        // Need to handle nested stuff somehow
        
        let (sql, bindings) = QueryHelpers.groupSQL(values: query.wheres)
        if (sql.count > 0) {
            let conjunction = query is JoinClause ? "on" : "where"
            let clauses = QueryHelpers.removeLeadingBoolean(
                sql.joined(separator: " ")
            )
            return SQL("\(conjunction) \(clauses)", bindings: bindings)
        }
        return nil
    }
    
    private func compileColumns(_ query: Query, columns: [SQL]) -> SQL {
        let select = query.isDistinct ? "select distinct" : "select"
        let (sql, bindings) = QueryHelpers.groupSQL(values: columns)
        return SQL("\(select) \(sql.joined(separator: ", "))", bindings: bindings)
    }

    private func compileFrom(_ query: Query, table: String?) throws -> SQL {
        guard let table = table else { throw GrammarError.missingTable }
        return SQL("from \(table)")
    }
}

/// An abstraction around various supported SQL column types.
/// `Grammar`s will map the `ColumnType` to the backing
/// dialect type string.
public enum ColumnType {
    /// Self incrementing integer.
    case increments
    /// Integer.
    case int
    /// Big integer.
    case bigInt
    /// Double.
    case double
    /// String, with a given max length.
    case string(StringLength)
    /// UUID.
    case uuid
    /// Boolean.
    case bool
    /// Date.
    case date
    /// JSON.
    case json
}

/// The length of an SQL string column in characters.
public enum StringLength {
    /// This value of this column can be any number of characters.
    case unlimited
    /// This value of this column must be at most the provided number
    /// of characters.
    case limit(Int)
}

extension CreateColumn {
    /// Convert this `CreateColumn` to a `String` for inserting into
    /// an SQL statement.
    ///
    /// - Returns: The SQL `String` describing this column and any
    ///   table level constraints to add.
    func sqlString(with grammar: Grammar) -> (String, [String]) {
        var baseSQL = "\(self.column) \(grammar.typeString(for: self.type))"
        var tableConstraints: [String] = []
        for constraint in self.constraints {
            switch constraint {
            case .notNull:
                baseSQL.append(" NOT NULL")
            case .primaryKey:
                tableConstraints.append("PRIMARY KEY (\(self.column))")
            case .unique:
                tableConstraints.append("UNIQUE (\(self.column))")
            case let .default(val):
                baseSQL.append(" DEFAULT \(val)")
            case let .foreignKey(column, table, onDelete, onUpdate):
                var fkBase = "FOREIGN KEY (\(self.column)) REFERENCES \(table) (\(column))"
                if let delete = onDelete { fkBase.append(" ON DELETE \(delete.rawValue)") }
                if let update = onUpdate { fkBase.append(" ON UPDATE \(update.rawValue)") }
                tableConstraints.append(fkBase)
            case .unsigned:
                if grammar.allowsUnsigned() {
                    baseSQL.append(" UNSIGNED")
                }
            }
        }
        
        return (baseSQL, tableConstraints)
    }
}

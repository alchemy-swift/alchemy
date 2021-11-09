import Foundation
import OrderedCollections

struct GrammarError: Error {
    let message: String
    static let missingTable = GrammarError(message: "Missing a table to run the query on.")
}

/// Used for compiling query builders into raw SQL statements.
open class Grammar {
    open var isSQLite: Bool { false }
    
    public init() {}

    // MARK: Compiling Query Builders
    
    open func compileSelect(query: Query) throws -> SQL {
        return [
            compileColumns(query, columns: query.columns),
            try compileFrom(query, table: query.from),
            compileJoins(query, joins: query.joins),
            compileWheres(query),
            compileGroups(query, groups: query.groups),
            compileHavings(query),
            compileOrders(query, orders: query.orders),
            compileLimit(query, limit: query.limit),
            compileOffset(query, offset: query.offset),
            query.lock.map { SQL($0) }
        ].compactMap { $0 }.joined()
    }

    open func compileJoins(_ query: Query, joins: [Query.Join]?) -> SQL? {
        guard let joins = joins else { return nil }
        var bindings: [SQLValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join) else {
                return nil
            }
            bindings += whereSQL.bindings
            if let nestedJoins = join.joins,
                let nestedSQL = compileJoins(query, joins: nestedJoins) {
                bindings += nestedSQL.bindings
                return self.trim("\(join.type) join (\(join.table)\(nestedSQL.statement)) \(whereSQL.statement)")
            }
            return self.trim("\(join.type) join \(join.table) \(whereSQL.statement)")
        }.joined(separator: " ")
        return SQL(query, bindings: bindings)
    }

    open func compileGroups(_ query: Query, groups: [String]) -> SQL? {
        if groups.isEmpty { return nil }
        return SQL("group by \(groups.joined(separator: ", "))")
    }

    open func compileHavings(_ query: Query) -> SQL? {
        guard query.havings.count > 0 else {
            return nil
        }
        
        let sql = query.havings.joined().droppingLeadingBoolean()
        return SQL("having \(sql.statement)", bindings: sql.bindings)
    }

    open func compileOrders(_ query: Query, orders: [Query.Order]) -> SQL? {
        if orders.isEmpty { return nil }
        let ordersSQL = orders.map { $0.sql.statement }.joined(separator: ", ")
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

    open func compileInsert(_ query: Query, values: [OrderedDictionary<String, SQLValueConvertible>]) throws -> SQL {
        
        guard let table = query.from else { throw GrammarError.missingTable }

        if values.isEmpty {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].map { $0.key }.joined(separator: ", ")
        var parameters: [SQLValue] = []
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
    
    open func insert(_ values: [OrderedDictionary<String, SQLValueConvertible>], query: Query, returnItems: Bool) async throws -> [SQLRow] {
        let sql = try compileInsert(query, values: values)
        return try await query.database.runRawQuery(sql.statement, values: sql.bindings)
    }
    
    open func compileUpdate(_ query: Query, values: [String: SQLValueConvertible]) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        var bindings: [SQLValue] = []
        let columnSQL = compileUpdateColumns(query, values: values)

        var base = "update \(table)"
        if let clauses = query.joins,
            let joinSQL = compileJoins(query, joins: clauses) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " set \(columnSQL.statement)"

        if let whereSQL = compileWheres(query) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.statement)"
        }
        return SQL(base, bindings: bindings)
    }

    open func compileUpdateColumns(_ query: Query, values: [String: SQLValueConvertible]) -> SQL {
        var bindings: [SQLValue] = []
        var parts: [String] = []
        
        for value in values {
            if let expression = value.value as? SQL {
                parts.append("\(value.key) = \(expression.statement)")
            } else {
                bindings.append(value.value.value)
                parts.append("\(value.key) = ?")
            }
        }

        return SQL(parts.joined(separator: ", "), bindings: bindings)
    }

    open func compileDelete(_ query: Query) throws -> SQL {
        guard let table = query.from else { throw GrammarError.missingTable }
        if let whereSQL = compileWheres(query) {
            return SQL("delete from \(table) \(whereSQL.statement)", bindings: whereSQL.bindings)
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
        
        let drops = dropColumns.map { "DROP COLUMN \($0.sqlEscaped)" }
        return [
            SQL("""
                ALTER TABLE \(table)
                    \((adds + drops + constraints).joined(separator: ",\n    "))
                """)]
    }
    
    open func compileRenameColumn(table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column.sqlEscaped) TO \(to.sqlEscaped)")
    }
    
    /// Compile the given create indexes into SQL.
    ///
    /// - Parameter table: The name of the table this index will be
    ///   created on.
    /// - Returns: SQL objects for creating these indexes on the given table.
    open func compileCreateIndexes(table: String, indexes: [CreateIndex]) -> [SQL] {
        indexes.map { index in
            let indexType = index.isUnique ? "UNIQUE INDEX" : "INDEX"
            let indexName = index.name(table: table)
            let indexColumns = "(\(index.columns.map(\.sqlEscaped).joined(separator: ", ")))"
            return SQL("CREATE \(indexType) \(indexName) ON \(table) \(indexColumns)")
        }
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

    private func parameterize(_ values: [SQLValueConvertible]) -> String {
        return values.map { parameter($0) }.joined(separator: ", ")
    }

    private func parameter(_ value: SQLValueConvertible) -> String {
        if let value = value as? SQL {
            return value.statement
        }
        
        return "?"
    }

    private func trim(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func compileWheres(_ query: Query) -> SQL? {
        guard query.wheres.count > 0 else {
            return nil
        }
        
        let conjunction = query is Query.Join ? "on" : "where"
        let sql = query.wheres.joined().droppingLeadingBoolean()
        return SQL("\(conjunction) \(sql.statement)", bindings: sql.bindings)
    }
    
    private func compileColumns(_ query: Query, columns: [String]) -> SQL {
        let select = query.isDistinct ? "select distinct" : "select"
        return SQL("\(select) \(columns.joined(separator: ", "))")
    }

    private func compileFrom(_ query: Query, table: String?) throws -> SQL {
        guard let table = table else { throw GrammarError.missingTable }
        return SQL("from \(table)")
    }
}

extension CreateColumn {
    /// Convert this `CreateColumn` to a `String` for inserting into
    /// an SQL statement.
    ///
    /// - Returns: The SQL `String` describing this column and any
    ///   table level constraints to add.
    fileprivate func sqlString(with grammar: Grammar) -> (String, [String]) {
        let columnEscaped = self.column.sqlEscaped
        var baseSQL = "\(columnEscaped) \(grammar.typeString(for: self.type))"
        var tableConstraints: [String] = []
        for constraint in self.constraints {
            switch constraint {
            case .notNull:
                baseSQL.append(" NOT NULL")
            case .primaryKey:
                if type != .increments || !grammar.isSQLite {
                    tableConstraints.append("PRIMARY KEY (\(columnEscaped))")
                }
            case .unique:
                tableConstraints.append("UNIQUE (\(columnEscaped))")
            case let .default(val):
                baseSQL.append(" DEFAULT \(val)")
            case let .foreignKey(column, table, onDelete, onUpdate):
                var fkBase = "FOREIGN KEY (\(columnEscaped)) REFERENCES \(table) (\(column.sqlEscaped))"
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

extension String {
    var sqlEscaped: String {
        "\"\(self)\""
    }
}

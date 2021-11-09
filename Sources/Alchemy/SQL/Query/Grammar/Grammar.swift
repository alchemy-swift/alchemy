import Foundation

/// Used for compiling query builders into raw SQL statements.
open class Grammar {
    open var isSQLite: Bool { false }
    
    public init() {}

    // MARK: Compiling Query Builder
    
    open func compileSelect(query: Query) throws -> SQL {
        let select = query.isDistinct ? "select distinct" : "select"
        return [
            SQL("\(select) \(query.columns.joined(separator: ", "))"),
            SQL("from \(query.from)"),
            compileJoins(query.joins),
            compileWheres(query.wheres, isJoin: query is Query.Join),
            compileGroups(query.groups),
            compileHavings(query.havings),
            compileOrders(query.orders),
            compileLimit(query.limit),
            compileOffset(query.offset),
            query.lock.map { SQL($0) }
        ].compactMap { $0 }.joined()
    }

    open func compileJoins(_ joins: [Query.Join]) -> SQL? {
        guard !joins.isEmpty else {
            return nil
        }
        
        var bindings: [SQLValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join.wheres, isJoin: true) else {
                return nil
            }
            
            bindings += whereSQL.bindings
            if let nestedSQL = compileJoins(join.joins) {
                bindings += nestedSQL.bindings
                return "\(join.type) join (\(join.table)\(nestedSQL.statement)) \(whereSQL.statement)"
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            return "\(join.type) join \(join.table) \(whereSQL.statement)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined(separator: " ")
        
        return SQL(query, bindings: bindings)
    }
    
    open func compileWheres(_ wheres: [Query.Where], isJoin: Bool) -> SQL? {
        guard wheres.count > 0 else {
            return nil
        }
        
        let conjunction = isJoin ? "on" : "where"
        let sql = wheres.joined().droppingLeadingBoolean()
        return SQL("\(conjunction) \(sql.statement)", bindings: sql.bindings)
    }

    open func compileGroups(_ groups: [String]) -> SQL? {
        guard !groups.isEmpty else {
            return nil
        }
        
        return SQL("group by \(groups.joined(separator: ", "))")
    }

    open func compileHavings(_ havings: [Query.Where]) -> SQL? {
        guard havings.count > 0 else {
            return nil
        }
        
        let sql = havings.joined().droppingLeadingBoolean()
        return SQL("having \(sql.statement)", bindings: sql.bindings)
    }

    open func compileOrders(_ orders: [Query.Order]) -> SQL? {
        guard !orders.isEmpty else {
            return nil
        }
        
        let ordersSQL = orders.map { $0.sql.statement }.joined(separator: ", ")
        return SQL("order by \(ordersSQL)")
    }

    open func compileLimit(_ limit: Int?) -> SQL? {
        limit.map { SQL("limit \($0)") }
    }

    open func compileOffset(_ offset: Int?) -> SQL? {
        offset.map { SQL("offset \($0)") }
    }

    open func compileInsert(_ table: String, values: [[String: SQLValueConvertible]]) throws -> SQL {
        guard !values.isEmpty else {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].map { $0.key }
        var parameters: [SQLValue] = []
        var placeholders: [String] = []

        for value in values {
            let orderedValues = columns.compactMap { value[$0]?.value }
            parameters.append(contentsOf: orderedValues)
            placeholders.append("(\(parameterize(orderedValues)))")
        }
        
        let columnsJoined = columns.joined(separator: ", ")
        return SQL("insert into \(table) (\(columnsJoined)) values \(placeholders.joined(separator: ", "))", bindings: parameters)
    }
    
    open func insert(
        _ table: String,
        values: [[String: SQLValueConvertible]],
        database: DatabaseDriver,
        returnItems: Bool
    ) async throws -> [SQLRow] {
        let sql = try compileInsert(table, values: values)
        return try await database.runRawQuery(sql.statement, values: sql.bindings)
    }
    
    open func compileUpdate(
        _ table: String,
        joins: [Query.Join],
        wheres: [Query.Where],
        values: [String: SQLValueConvertible]
    ) throws -> SQL {
        var bindings: [SQLValue] = []
        let columnSQL = values.map { key, val in
            if let expression = val as? SQL {
                return SQL("\(key) = \(expression.statement)")
            } else {
                return SQL("\(key) = ?", bindings: [val.value.value])
            }
        }.reduce(SQL()) { (lhs: SQL, rhs: SQL) -> SQL in
            SQL("\(lhs.statement), \(rhs.statement)", bindings: lhs.bindings + rhs.bindings)
        }
        
        var base = "update \(table)"
        if let joinSQL = compileJoins(joins) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " set \(columnSQL.statement)"

        if let whereSQL = compileWheres(wheres, isJoin: false) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.statement)"
        }
        
        return SQL(base, bindings: bindings)
    }

    open func compileDelete(_ table: String, wheres: [Query.Where]) throws -> SQL {
        if let whereSQL = compileWheres(wheres, isJoin: false) {
            return SQL("delete from \(table) \(whereSQL.statement)", bindings: whereSQL.bindings)
        } else {
            return SQL("delete from \(table)")
        }
    }
    
    // MARK: - Compiling Migrations
    
    open func compileCreateTable(_ table: String, ifNotExists: Bool, columns: [CreateColumn]) -> SQL {
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
    
    open func compileRenameTable(_ table: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME TO \(to)")
    }
    
    open func compileDropTable(_ table: String) -> SQL {
        SQL("DROP TABLE \(table)")
    }
    
    open func compileAlterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn]) -> [SQL] {
        guard !dropColumns.isEmpty || !addColumns.isEmpty else {
            return []
        }
        
        var adds: [String] = []
        var constraints: [String] = []
        for (sql, tableConstraints) in addColumns.map({ $0.sqlString(with: self) }) {
            adds.append("ADD COLUMN \(sql)")
            constraints.append(contentsOf: tableConstraints.map { "ADD \($0)" })
        }
        
        let drops = dropColumns.map { "DROP COLUMN \($0.escapedColumn)" }
        return [
            SQL("""
                ALTER TABLE \(table)
                    \((adds + drops + constraints).joined(separator: ",\n    "))
                """)]
    }
    
    open func compileRenameColumn(on table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column.escapedColumn) TO \(to.escapedColumn)")
    }
    
    /// Compile the given create indexes into SQL.
    ///
    /// - Parameter table: The name of the table this index will be
    ///   created on.
    /// - Returns: SQL objects for creating these indexes on the given table.
    open func compileCreateIndexes(on table: String, indexes: [CreateIndex]) -> [SQL] {
        indexes.map { index in
            let indexType = index.isUnique ? "UNIQUE INDEX" : "INDEX"
            let indexName = index.name(table: table)
            let indexColumns = "(\(index.columns.map(\.escapedColumn).joined(separator: ", ")))"
            return SQL("CREATE \(indexType) \(indexName) ON \(table) \(indexColumns)")
        }
    }
    
    open func compileDropIndex(on table: String, indexName: String) -> SQL {
        SQL("DROP INDEX \(indexName)")
    }
    
    // MARK: - Misc
    
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
        values.map { ($0 as? SQL)?.statement ?? "?" }.joined(separator: ", ")
    }
}

extension CreateColumn {
    /// Convert this `CreateColumn` to a `String` for inserting into
    /// an SQL statement.
    ///
    /// - Returns: The SQL `String` describing this column and any
    ///   table level constraints to add.
    fileprivate func sqlString(with grammar: Grammar) -> (String, [String]) {
        let columnEscaped = column.escapedColumn
        var baseSQL = "\(columnEscaped) \(grammar.typeString(for: type))"
        var tableConstraints: [String] = []
        for constraint in constraints {
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
                var fkBase = "FOREIGN KEY (\(columnEscaped)) REFERENCES \(table) (\(column.escapedColumn))"
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
    fileprivate var escapedColumn: String {
        "\"\(self)\""
    }
}

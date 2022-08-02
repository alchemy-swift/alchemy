import Foundation

/// Used for compiling query builders into raw SQL statements.
open class Grammar {
    public init() {}

    // MARK: Compiling Query Builder
    
    open func compileSelect(
        table: String,
        isDistinct: Bool,
        columns: [String],
        joins: [Query.Join],
        wheres: [Query.Where],
        groups: [String],
        havings: [Query.Where],
        orders: [Query.Order],
        limit: Int?,
        offset: Int?,
        lock: Query.Lock?
    ) throws -> SQL {
        let select = isDistinct ? "select distinct" : "select"
        return [
            SQL("\(select) \(columns.joined(separator: ", "))"),
            SQL("from \(table)"),
            compileJoins(joins),
            compileWheres(wheres),
            compileGroups(groups),
            compileHavings(havings),
            compileOrders(orders),
            compileLimit(limit),
            compileOffset(offset),
            compileLock(lock)
        ].compactMap { $0 }.joinedSQL()
    }

    open func compileJoins(_ joins: [Query.Join]) -> SQL? {
        guard !joins.isEmpty else {
            return nil
        }
        
        var bindings: [SQLValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join.joinWheres, isJoin: true) else {
                return nil
            }
            
            bindings += whereSQL.bindings
            if let nestedSQL = compileJoins(join.joins) {
                bindings += nestedSQL.bindings
                return "\(join.type) join (\(join.joinTable)\(nestedSQL.statement)) \(whereSQL.statement)"
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            return "\(join.type) join \(join.joinTable) \(whereSQL.statement)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined(separator: " ")
        
        return SQL(query, bindings: bindings)
    }
    
    open func compileWheres(_ wheres: [Query.Where], isJoin: Bool = false) -> SQL? {
        guard wheres.count > 0 else {
            return nil
        }
        
        let conjunction = isJoin ? "on" : "where"
        let sql = wheres.joinedSQL().droppingLeadingBoolean()
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
        
        let sql = havings.joinedSQL().droppingLeadingBoolean()
        return SQL("having \(sql.statement)", bindings: sql.bindings)
    }

    open func compileOrders(_ orders: [Query.Order]) -> SQL? {
        guard !orders.isEmpty else {
            return nil
        }
        
        let ordersSQL = orders
            .map { "\($0.column) \($0.direction)" }
            .joined(separator: ", ")
        return SQL("order by \(ordersSQL)")
    }

    open func compileLimit(_ limit: Int?) -> SQL? {
        limit.map { SQL("limit \($0)") }
    }

    open func compileOffset(_ offset: Int?) -> SQL? {
        offset.map { SQL("offset \($0)") }
    }

    open func compileInsert(_ table: String, values: [[String: SQLValueConvertible]]) -> SQL {
        guard !values.isEmpty else {
            return SQL("insert into \(table) default values")
        }

        let columns = values[0].map { $0.key }
        var parameters: [SQLValue] = []
        var placeholders: [String] = []

        for value in values {
            let orderedValues = columns.compactMap { value[$0]?.sqlValue }
            parameters.append(contentsOf: orderedValues)
            placeholders.append("(\(parameterize(orderedValues)))")
        }
        
        let columnsJoined = columns.joined(separator: ", ")
        return SQL("insert into \(table) (\(columnsJoined)) values \(placeholders.joined(separator: ", "))", bindings: parameters)
    }
    
    open func compileInsertReturn(_ table: String, values: [[String: SQLValueConvertible]]) -> [SQL] {
        let insert = compileInsert(table, values: values)
        return [SQL("\(insert.statement) returning *", bindings: insert.bindings)]
    }
    
    open func compileUpdate(_ table: String, joins: [Query.Join], wheres: [Query.Where], values: [String: SQLValueConvertible]) throws -> SQL {
        var bindings: [SQLValue] = []
        let columnStatements: [SQL] = values.map { key, val in
            if let expression = val as? SQL {
                return SQL("\(key) = \(expression.statement)")
            } else {
                return SQL("\(key) = ?", bindings: [val.sqlValue.sqlValue])
            }
        }
        
        let columnSQL = SQL(columnStatements.map(\.statement).joined(separator: ", "), bindings: columnStatements.flatMap(\.bindings))
        
        var base = "update \(table)"
        if let joinSQL = compileJoins(joins) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " set \(columnSQL.statement)"

        if let whereSQL = compileWheres(wheres) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.statement)"
        }
        
        return SQL(base, bindings: bindings)
    }

    open func compileDelete(_ table: String, wheres: [Query.Where]) throws -> SQL {
        if let whereSQL = compileWheres(wheres) {
            return SQL("delete from \(table) \(whereSQL.statement)", bindings: whereSQL.bindings)
        } else {
            return SQL("delete from \(table)")
        }
    }
    
    open func compileLock(_ lock: Query.Lock?) -> SQL? {
        guard let lock = lock else {
            return nil
        }
        
        var string = ""
        switch lock.strength {
        case .update:
            string = "FOR UPDATE"
        case .share:
            string = "FOR SHARE"
        }
        
        switch lock.option {
        case .noWait:
            string.append(" NO WAIT")
        case .skipLocked:
            string.append(" SKIP LOCKED")
        case .none:
            break
        }
        
        return SQL(string)
    }
    
    // MARK: - Compiling Migrations
    
    open func compileCreateTable(_ table: String, ifNotExists: Bool, columns: [CreateColumn]) -> SQL {
        var columnStrings: [String] = []
        var constraintStrings: [String] = []
        for (column, constraints) in columns.map({ createColumnString(for: $0) }) {
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
    
    open func compileAlterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn], allowConstraints: Bool = true) -> [SQL] {
        guard !dropColumns.isEmpty || !addColumns.isEmpty else {
            return []
        }
        
        var adds: [String] = []
        var constraints: [String] = []
        for (sql, tableConstraints) in addColumns.map({ createColumnString(for: $0) }) {
            adds.append("ADD COLUMN \(sql)")
            if allowConstraints {
                constraints.append(contentsOf: tableConstraints.map { "ADD \($0)" })
            }
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
    
    open func columnTypeString(for type: ColumnType) -> String {
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
    
    /// Convert a `CreateColumn` to a `String` for inserting into an SQL
    /// statement.
    ///
    /// - Returns: The SQL `String` describing the column and any table level
    ///   constraints to add.
    open func createColumnString(for column: CreateColumn) -> (String, [String]) {
        let columnEscaped = column.name.escapedColumn
        var baseSQL = "\(columnEscaped) \(columnTypeString(for: column.type))"
        var tableConstraints: [String] = []
        for constraint in column.constraints {
            guard let constraintString = columnConstraintString(for: constraint, on: column.name.escapedColumn, of: column.type) else {
                continue
            }
            
            switch constraint {
            case .notNull:
                baseSQL.append(" \(constraintString)")
            case .default:
                baseSQL.append(" \(constraintString)")
            case .unsigned:
                baseSQL.append(" \(constraintString)")
            case .primaryKey:
                tableConstraints.append(constraintString)
            case .unique:
                tableConstraints.append(constraintString)
            case .foreignKey:
                tableConstraints.append(constraintString)
            }
        }
        
        return (baseSQL, tableConstraints)
    }
    
    open func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .notNull:
            return "NOT NULL"
        case .default(let string):
            return "DEFAULT \(string)"
        case .primaryKey:
            return "PRIMARY KEY (\(column))"
        case .unique:
            return "UNIQUE (\(column))"
        case .foreignKey(let fkColumn, let table, let onDelete, let onUpdate):
            var fkBase = "FOREIGN KEY (\(column)) REFERENCES \(table) (\(fkColumn.escapedColumn))"
            if let delete = onDelete { fkBase.append(" ON DELETE \(delete.rawValue)") }
            if let update = onUpdate { fkBase.append(" ON UPDATE \(update.rawValue)") }
            return fkBase
        case .unsigned:
            return nil
        }
    }
    
    open func jsonLiteral(for jsonString: String) -> String {
        "'\(jsonString)'::jsonb"
    }
    
    private func parameterize(_ values: [SQLValueConvertible]) -> String {
        values.map { ($0 as? SQL)?.statement ?? "?" }.joined(separator: ", ")
    }
}

extension String {
    fileprivate var escapedColumn: String {
        "\"\(self)\""
    }
}

extension Query.Where: SQLConvertible {
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
        case .nested(let wheres):
            let nestedSQL = wheres.joinedSQL().droppingLeadingBoolean()
            return SQL("\(boolean) (\(nestedSQL.statement))", bindings: nestedSQL.bindings)
        case .in(let key, let values, let type):
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            return SQL("\(boolean) \(key) \(type)(\(placeholders))", bindings: values)
        case .raw(let sql):
            return SQL("\(boolean) \(sql.statement)", bindings: sql.bindings)
        }
    }
}

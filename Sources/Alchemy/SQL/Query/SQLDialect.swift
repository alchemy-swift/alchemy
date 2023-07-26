import Foundation

public protocol SQLDialect {

    // MARK: SELECT

    func select(isDistinct: Bool,
                columns: [String],
                table: String,
                joins: [SQLJoin],
                wheres: [SQLWhere],
                groups: [String],
                havings: [SQLWhere],
                orders: [SQLOrder],
                limit: Int?,
                offset: Int?,
                lock: SQLLock?) -> SQL

    func compileJoins(_ joins: [SQLJoin]) -> SQL?
    func compileWheres(_ wheres: [SQLWhere], isJoin: Bool) -> SQL?
    func compileGroups(_ groups: [String]) -> SQL?
    func compileHavings(_ havings: [SQLWhere]) -> SQL?
    func compileOrders(_ orders: [SQLOrder]) -> SQL?
    func compileLimit(_ limit: Int?) -> SQL?
    func compileOffset(_ offset: Int?) -> SQL?
    func compileLock(_ lock: SQLLock?) -> SQL?

    // MARK: Insert

    func insert(_ table: String, values: [[String: SQLValueConvertible]]) -> SQL
    func insertReturn(_ table: String, values: [[String: SQLValueConvertible]]) -> [SQL]

    // MARK: Update

    func update(table: String,
                joins: [SQLJoin],
                wheres: [SQLWhere],
                fields: [String: SQLValueConvertible]) -> SQL

    // MARK: Delete

    func delete(_ table: String, wheres: [SQLWhere]) -> SQL
}

// MARK: - Defaults

extension SQLDialect {
    public func select(isDistinct: Bool,
                       columns: [String],
                       table: String,
                       joins: [SQLJoin],
                       wheres: [SQLWhere],
                       groups: [String],
                       havings: [SQLWhere],
                       orders: [SQLOrder],
                       limit: Int?,
                       offset: Int?,
                       lock: SQLLock?) -> SQL {
        let select = isDistinct ? "SELECT DISTINCT" : "SELECT"
        return [
            SQL("\(select) \(columns.joined(separator: ", "))"),
            SQL("FROM \(table)"),
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

    public func compileJoins(_ joins: [SQLJoin]) -> SQL? {
        guard !joins.isEmpty else {
            return nil
        }

        var bindings: [SQLValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join.wheres, isJoin: true) else {
                return nil
            }

            bindings += whereSQL.bindings
            return "\(join.type.rawValue) JOIN \(join.table) \(whereSQL.statement)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined(separator: " ")

        return SQL(query, bindings: bindings)
    }

    public func compileWheres(_ wheres: [SQLWhere], isJoin: Bool = false) -> SQL? {
        guard wheres.count > 0 else {
            return nil
        }

        let conjunction = isJoin ? "ON" : "WHERE"
        let sql = wheres.joinedSQL().droppingLeadingBoolean()
        return SQL("\(conjunction) \(sql.statement)", bindings: sql.bindings)
    }

    public func compileGroups(_ groups: [String]) -> SQL? {
        guard !groups.isEmpty else {
            return nil
        }

        return SQL("GROUP BY \(groups.joined(separator: ", "))")
    }

    public func compileHavings(_ havings: [SQLWhere]) -> SQL? {
        guard havings.count > 0 else {
            return nil
        }

        let sql = havings.joinedSQL().droppingLeadingBoolean()
        return SQL("HAVING \(sql.statement)", bindings: sql.bindings)
    }

    public func compileOrders(_ orders: [SQLOrder]) -> SQL? {
        guard !orders.isEmpty else {
            return nil
        }

        let ordersSQL = orders
            .map { "\($0.column) \($0.direction)" }
            .joined(separator: ", ")
        return SQL("ORDER BY \(ordersSQL)")
    }

    public func compileLimit(_ limit: Int?) -> SQL? {
        limit.map { SQL("LIMIT \($0)") }
    }

    public func compileOffset(_ offset: Int?) -> SQL? {
        offset.map { SQL("OFFSET \($0)") }
    }

    public func compileLock(_ lock: SQLLock?) -> SQL? {
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

    public func insert(_ table: String, values: [[String: SQLValueConvertible]]) -> SQL {
        guard !values.isEmpty else {
            return SQL("INSERT INTO \(table) DEFAULT VALUES")
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
        return SQL("INSERT INTO \(table) (\(columnsJoined)) VALUES \(placeholders.joined(separator: ", "))", bindings: parameters)
    }

    public func insertReturn(_ table: String, values: [[String: SQLValueConvertible]]) -> [SQL] {
        let insert = insert(table, values: values)
        return [SQL("\(insert.statement) RETURNING *", bindings: insert.bindings)]
    }

    public func update(table: String,
                       joins: [SQLJoin],
                       wheres: [SQLWhere],
                       fields: [String: SQLValueConvertible]) -> SQL {
        var bindings: [SQLValue] = []
        let columnStatements: [SQL] = fields.map { key, val in
            if let expression = val as? SQL {
                return SQL("\(key) = \(expression.statement)")
            } else {
                return SQL("\(key) = ?", bindings: [val.sqlValue.sqlValue])
            }
        }

        let columnSQL = SQL(columnStatements.map(\.statement).joined(separator: ", "), bindings: columnStatements.flatMap(\.bindings))

        var base = "UPDATE \(table)"
        if let joinSQL = compileJoins(joins) {
            bindings += joinSQL.bindings
            base += " \(joinSQL)"
        }

        bindings += columnSQL.bindings
        base += " SET \(columnSQL.statement)"

        if let whereSQL = compileWheres(wheres) {
            bindings += whereSQL.bindings
            base += " \(whereSQL.statement)"
        }

        return SQL(base, bindings: bindings)
    }

    public func delete(_ table: String, wheres: [SQLWhere]) -> SQL {
        if let whereSQL = compileWheres(wheres) {
            return SQL("DELETE FROM \(table) \(whereSQL.statement)", bindings: whereSQL.bindings)
        } else {
            return SQL("DELETE FROM \(table)")
        }
    }

    private func parameterize(_ values: [SQLValueConvertible]) -> String {
        values.map { ($0 as? SQL)?.statement ?? "?" }.joined(separator: ", ")
    }
}

/// Used for compiling query builders into raw SQL statements.
open class Grammar {
    public init() {}

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

extension SQLWhere {
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
        case .in(let key, let values):
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            return SQL("\(boolean) \(key) IN (\(placeholders))", bindings: values)
        case .notIn(let key, let values):
            let placeholders = Array(repeating: "?", count: values.count).joined(separator: ", ")
            return SQL("\(boolean) \(key) NOT IN (\(placeholders))", bindings: values)
        case .raw(let sql):
            return SQL("\(boolean) \(sql.statement)", bindings: sql.bindings)
        }
    }
}

extension Array where Element == SQL {
    func joinedSQL() -> SQL {
        return SQL(map(\.statement).joined(separator: " "), bindings: flatMap(\.bindings))
    }
}

extension Array where Element == SQLWhere {
    func joinedSQL() -> SQL {
        let statements = map(\.sql)
        return SQL(statements.map(\.statement).joined(separator: " "), bindings: statements.flatMap(\.bindings))
    }
}

extension SQL {
    func droppingLeadingBoolean() -> SQL {
        SQL(statement.droppingPrefix("and ").droppingPrefix("or "), bindings: bindings)
    }
}

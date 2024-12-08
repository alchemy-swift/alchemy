public protocol SQLGrammar {

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

    // MARK: INSERT

    func insert(_ table: String, columns: [String], sql: SQL) -> SQL
    func insert(_ table: String, values: [SQLFields]) -> SQL
    func insertReturn(_ table: String, values: [SQLFields]) -> [SQL]

    // MARK: UPSERT

    func upsert(_ table: String, values: [SQLFields], conflictKeys: [String]) -> SQL
    func upsertReturn(_ table: String, values: [SQLFields], conflictKeys: [String]) -> [SQL]

    // MARK: UPDATE

    func update(table: String,
                joins: [SQLJoin],
                wheres: [SQLWhere],
                fields: SQLFields) -> SQL

    // MARK: DELETE

    func delete(_ table: String, wheres: [SQLWhere]) -> SQL

    // MARK: Schema

    func createTable(_ table: String, ifNotExists: Bool, columns: [CreateColumn]) -> SQL
    func renameTable(_ table: String, to: String) -> SQL
    func dropTable(_ table: String) -> SQL
    func alterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn], alterColumns: [CreateColumn]) -> [SQL]
    func renameColumn(on table: String, column: String, to: String) -> SQL
    func createIndexes(on table: String, indexes: [CreateIndex]) -> [SQL]
    func dropIndex(on table: String, indexName: String) -> SQL
    func hasTable(_ table: String) -> SQL

    // MARK: Misc

    func columnTypeString(for type: ColumnType) -> String
    func createColumnString(for column: CreateColumn) -> (definition: String, constraints: [String])
    func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String?
    func jsonLiteral(for jsonString: String) -> String
    func random() -> String
}

// MARK: - Defaults

extension SQLGrammar {

    // MARK: SELECT

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
            "\(select) \(columns.joined(separator: ", "))",
            "FROM \(table)",
            compileJoins(joins),
            compileWheres(wheres),
            compileGroups(groups),
            compileHavings(havings),
            compileOrders(orders),
            compileLimit(limit),
            compileOffset(offset),
            compileLock(lock)
        ].compactMap { $0 }.joined()
    }

    public func compileJoins(_ joins: [SQLJoin]) -> SQL? {
        guard !joins.isEmpty else {
            return nil
        }

        var parameters: [SQLValue] = []
        let query = joins.compactMap { join -> String? in
            guard let whereSQL = compileWheres(join.wheres, isJoin: true) else {
                return nil
            }

            parameters += whereSQL.parameters
            return "\(join.type.rawValue) JOIN \(join.table) \(whereSQL.statement)"
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined(separator: " ")

        return SQL(query, parameters: parameters)
    }

    public func compileWheres(_ wheres: [SQLWhere], isJoin: Bool = false) -> SQL? {
        guard wheres.count > 0 else {
            return nil
        }

        let conjunction = isJoin ? "ON" : "WHERE"
        let sql = wheres.joined()
        return SQL("\(conjunction) \(sql.statement)", parameters: sql.parameters)
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

        let sql = havings.joined()
        return SQL("HAVING \(sql.statement)", parameters: sql.parameters)
    }

    public func compileOrders(_ orders: [SQLOrder]) -> SQL? {
        guard !orders.isEmpty else {
            return nil
        }

        let ordersSQL = orders
            .map { "\($0.column) \($0.direction.rawValue)" }
            .joined(separator: ", ")
        return SQL("ORDER BY \(ordersSQL)")
    }

    public func compileLimit(_ limit: Int?) -> SQL? {
        limit.map { "LIMIT \($0)" }
    }

    public func compileOffset(_ offset: Int?) -> SQL? {
        offset.map { "OFFSET \($0)" }
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

    // MARK: INSERT

    public func insert(_ table: String, columns: [String], sql: SQL) -> SQL {
        SQL("INSERT INTO \(table)(\(columns.joined(separator: ", "))) \(sql.statement)", parameters: sql.parameters)
    }

    public func insert(_ table: String, values: [SQLFields]) -> SQL {
        guard !values.isEmpty else {
            return SQL("INSERT INTO \(table) DEFAULT VALUES")
        }

        let columns = Set(values.flatMap(\.keys))
        var input: [SQLConvertible] = []
        var placeholders: [String] = []

        for value in values {
            let orderedValues = columns.map { value[$0]?.sql ?? .null }
            input.append(contentsOf: orderedValues)
            placeholders.append("(\(parameterize(orderedValues)))")
        }

        let columnsJoined = columns.joined(separator: ", ")
        return SQL("INSERT INTO \(table) (\(columnsJoined)) VALUES \(placeholders.joined(separator: ", "))", input: input)
    }

    public func insertReturn(_ table: String, values: [SQLFields]) -> [SQL] {
        [insert(table, values: values) + " RETURNING *"]
    }

    // MARK: UPSERT

    public func upsert(_ table: String, values: [SQLFields], conflictKeys: [String]) -> SQL {
        var upsert = insert(table, values: values)
        guard !values.isEmpty else {
            return upsert
        }

        let uniqueColumns = Set(values.flatMap(\.keys)).array
        let updateColumns = uniqueColumns.filter { !conflictKeys.contains($0) }

        let conflicts = conflictKeys.joined(separator: ", ")
        upsert = upsert + " ON CONFLICT (\(conflicts)) DO"
        if updateColumns.isEmpty {
            upsert = upsert + " NOTHING"
        } else {
            let updates = updateColumns.map { "\($0.inQuotes) = EXCLUDED.\($0.inQuotes)" }.joined(separator: ", ")
            upsert = upsert + " UPDATE SET \(updates)"
        }

        return upsert
    }

    public func upsertReturn(_ table: String, values: [SQLFields], conflictKeys: [String]) -> [SQL] {
        [upsert(table, values: values, conflictKeys: conflictKeys) + " RETURNING *"]
    }

    // MARK: UPDATE

    public func update(table: String,
                       joins: [SQLJoin],
                       wheres: [SQLWhere],
                       fields: SQLFields) -> SQL {
        var parameters: [SQLValue] = []
        var base = "UPDATE \(table)"
        if let joinSQL = compileJoins(joins) {
            parameters += joinSQL.parameters
            base += " \(joinSQL)"
        }

        let columnStatements = fields.map { SQL("\($0) = ?", input: [$1.sql]) }
        let columnSQL = SQL(columnStatements.map(\.statement).joined(separator: ", "), parameters: columnStatements.flatMap(\.parameters))
        parameters += columnSQL.parameters
        base += " SET \(columnSQL.statement)"

        if let whereSQL = compileWheres(wheres) {
            parameters += whereSQL.parameters
            base += " \(whereSQL.statement)"
        }

        return SQL(base, parameters: parameters)
    }

    // MARK: DELETE

    public func delete(_ table: String, wheres: [SQLWhere]) -> SQL {
        if let whereSQL = compileWheres(wheres) {
            return SQL("DELETE FROM \(table) \(whereSQL.statement)", parameters: whereSQL.parameters)
        } else {
            return SQL("DELETE FROM \(table)")
        }
    }

    private func parameterize(_ values: [SQLConvertible]) -> String {
        Array(repeating: "?", count: values.count).joined(separator: ", ")
    }

    // MARK: Schema

    public func createTable(_ table: String, ifNotExists: Bool, columns: [CreateColumn]) -> SQL {
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

    public func renameTable(_ table: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME TO \(to)")
    }

    public func dropTable(_ table: String) -> SQL {
        SQL("DROP TABLE \(table)")
    }

    public func alterTable(_ table: String, dropColumns: [String], addColumns: [CreateColumn], alterColumns: [CreateColumn]) -> [SQL] {
        guard !dropColumns.isEmpty || !addColumns.isEmpty || !alterColumns.isEmpty else {
            return []
        }

        var adds: [String] = []
        var constraints: [String] = []
        for (sql, tableConstraints) in addColumns.map({ createColumnString(for: $0) }) {
            adds.append("ADD COLUMN \(sql)")
            constraints.append(contentsOf: tableConstraints.map { "ADD \($0)" })
        }

        var updates: [String] = []
        for alter in alterColumns {
            updates.append("ALTER COLUMN \(alter.name) TYPE \(columnTypeString(for: alter.type))")
            for constraint in alter.constraints {
                switch constraint {
                case .nullable:
                    updates.append("ALTER COLUMN \(alter.name) DROP NOT NULL")
                case .notNull:
                    updates.append("ALTER COLUMN \(alter.name) SET NOT NULL")
                case let .default(value):
                    updates.append("ALTER COLUMN \(alter.name) SET DEFAULT \(value)")
                case .unsigned, .unique, .foreignKey, .primaryKey:
                    Log.warning("Changing UNSIGNED, UNIQUE, FOREIGN KEY, and PRIMARY KEY aren't available in ALTER TABLE, yet.")
                    continue
                }
            }
        }

        let drops = dropColumns.map { "DROP COLUMN \($0.inQuotes)" }
        return [
            SQL("""
                ALTER TABLE \(table)
                    \((adds + updates + drops + constraints).joined(separator: ",\n    "))
                """)]
    }

    public func renameColumn(on table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column.inQuotes) TO \(to.inQuotes)")
    }

    public func createIndexes(on table: String, indexes: [CreateIndex]) -> [SQL] {
        indexes.map { index in
            let indexType = index.isUnique ? "UNIQUE INDEX" : "INDEX"
            let indexName = index.name(table: table)
            let indexColumns = "(\(index.columns.map(\.inQuotes).joined(separator: ", ")))"
            return SQL("CREATE \(indexType) \(indexName) ON \(table) \(indexColumns)")
        }
    }

    public func dropIndex(on table: String, indexName: String) -> SQL {
        SQL("DROP INDEX \(indexName)")
    }

    public func hasTable(_ table: String) -> SQL {
        SQL("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = ?", parameters: [table])
    }

    // MARK: - Misc

    public func columnTypeString(for type: ColumnType) -> String {
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
    public func createColumnString(for column: CreateColumn) -> (definition: String, constraints: [String]) {
        let columnEscaped = column.name.inQuotes
        var baseSQL = "\(columnEscaped) \(columnTypeString(for: column.type))"
        var tableConstraints: [String] = []
        for constraint in column.constraints {
            guard let constraintString = columnConstraintString(for: constraint, on: column.name.inQuotes, of: column.type) else {
                continue
            }

            switch constraint {
            case .notNull:
                baseSQL.append(" \(constraintString)")
            case .nullable:
                continue
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

    public func columnConstraintString(for constraint: ColumnConstraint, on column: String, of type: ColumnType) -> String? {
        switch constraint {
        case .notNull:
            return "NOT NULL"
        case .nullable:
            return nil
        case .default(let string):
            return "DEFAULT \(string)"
        case .primaryKey:
            return "PRIMARY KEY (\(column))"
        case .unique:
            return "UNIQUE (\(column))"
        case .foreignKey(let fkColumn, let table, let onDelete, let onUpdate):
            var fkBase = "FOREIGN KEY (\(column)) REFERENCES \(table) (\(fkColumn.inQuotes))"
            if let delete = onDelete { fkBase.append(" ON DELETE \(delete.rawValue)") }
            if let update = onUpdate { fkBase.append(" ON UPDATE \(update.rawValue)") }
            return fkBase
        case .unsigned:
            return nil
        }
    }

    public func jsonLiteral(for jsonString: String) -> String {
        "'\(jsonString)'::jsonb"
    }

    public func random() -> String {
        "RANDOM()"
    }
}

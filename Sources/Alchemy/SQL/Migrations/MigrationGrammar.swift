open class MigrationGrammar {
    func compileCreate(table: String, columns: [CreateColumn]) -> SQL {
        SQL("""
            CREATE TABLE \(table) (
                \(columns.map { $0.toSQL() }.joined(separator: "\n    "))
            )
            """)
    }
    
    func compileRename(table: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME TO \(to)")
    }
    
    func compileDrop(table: String) -> SQL {
        SQL("DROP TABLE \(table)")
    }
    
    func compileAlter(table: String, dropColumns: [DropColumn], addColumns: [CreateColumn]) -> [SQL] {
        guard !dropColumns.isEmpty || !addColumns.isEmpty else {
            return []
        }
        
        let adds = addColumns.map { "ADD COLUMN \($0.toSQL())" }
        let drops = dropColumns.map { "DROP COLUMN \($0.column)" }
        return [SQL("""
                    ALTER TABLE \(table)
                    \((adds + drops).joined(separator: ",\n"))
                    """)]
    }
    
    func compileRenameColumn(table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column) TO \(to)")
    }
    
    func compileCreateIndexes(table: String, indexes: [CreateIndex]) -> [SQL] {
        indexes.map { SQL($0.toSQL(table: table)) }
    }
    
    func compileDropIndex(table: String, indexName: String) -> SQL {
        SQL("DROP INDEX \(indexName)")
    }
}

private extension CreateIndex {
    func toSQL(table: String) -> String {
        "CREATE \(self.isUnique ? "UNIQUE " : "")INDEX \(self.name(table: table)) ON \(table)"
    }
    
    private func name(table: String) -> String {
        ([table] + self.columns + [self.nameSuffix]).joined(separator: "_")
    }
    
    private var nameSuffix: String {
        self.isUnique ? "key" : "idx"
    }
}

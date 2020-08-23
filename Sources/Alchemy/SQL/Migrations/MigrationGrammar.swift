class MigrationGrammar {
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
    
    func compileTableChange(table: String, dropColumns: [String], addColumns: [CreateColumn]) -> SQL {
        SQL("""
            ALTER TABLE \(table)
            \(dropColumns.map { "DROP COLUMN \($0)" }.joined(separator: ",\n"))
            \(addColumns.map { "ADD COLUMN \($0.toSQL())" }.joined(separator: ",\n"))
            """)
    }
    
    func compileRenameColumn(table: String, column: String, to: String) -> SQL {
        SQL("ALTER TABLE \(table) RENAME COLUMN \(column) TO \(to)")
    }
}

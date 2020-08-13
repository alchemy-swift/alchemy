import Foundation

struct AlterTableBuilder: ColumnCreator {
    let table: String
    var dropColumns: [String] = []
    var addColumns: [CreateColumn] = []
    var renameColumns: [RenameColumn] = []
}

extension AlterTableBuilder {
    mutating func drop(column: String) {
        self.dropColumns.append(column)
    }
    
    mutating func rename(column: String, to: String) {
        self.renameColumns.append(RenameColumn(column: column, to: to))
    }
}

struct RenameColumn {
    let column: String
    let to: String
}

struct CreateColumn {
    let column: String
    let type: String
    let constraints: [String]
}

extension CreateColumn {
    func toSQL() -> String {
        "\(column) \(type) \(constraints.joined(separator: " "))"
    }
}

class MigrationGrammar {
    func compileCreate(table: String, columns: [CreateColumn]) -> SQL {
        SQL("""
            CREATE TABLE \(table) (
            \(columns.map { $0.toSQL() }.joined(separator: "\n\t"))
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

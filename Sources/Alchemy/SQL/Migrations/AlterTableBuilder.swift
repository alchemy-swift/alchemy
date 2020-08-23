import Foundation

final class AlterTableBuilder: ColumnCreator {
    let table: String
    var dropColumns: [String] = []
    var addColumns: [CreateColumn] = []
    var renameColumns: [RenameColumn] = []
    
    var builders: [ColumnBuilderErased] = []
    
    init(table: String) {
        self.table = table
    }
}

extension AlterTableBuilder {
    func drop(column: String) {
        self.dropColumns.append(column)
    }
    
    func rename(column: String, to: String) {
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

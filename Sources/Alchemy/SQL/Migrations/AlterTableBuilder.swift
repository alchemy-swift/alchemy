import Foundation

final class AlterTableBuilder: ColumnCreator, IndexCreator {
    let table: String
    
    /// Columns
    var dropColumns: [String] = []
    var addColumns: [CreateColumn] = []
    var renameColumns: [RenameColumn] = []
    
    /// Indexes
    var dropIndices: [String] = []
    
    var createIndices: [CreateIndex] = []
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

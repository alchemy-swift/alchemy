import Foundation

final class AlterTableBuilder: ColumnCreator, IndexCreator {
    let table: String
    
    /// Columns
    var dropColumns: [DropColumn] = []
    var renameColumns: [RenameColumn] = []
    
    /// Indexes
    var dropIndexes: [String] = []
    var createIndexes: [CreateIndex] = []
    var builders: [ColumnBuilderErased] = []
    
    init(table: String) {
        self.table = table
    }
}

extension AlterTableBuilder {
    func drop(column: String) {
        self.dropColumns.append(DropColumn(column: column))
    }
    
    func rename(column: String, to: String) {
        self.renameColumns.append(RenameColumn(column: column, to: to))
    }
    
    func drop(index: String) {
        self.dropIndexes.append(index)
    }
}

struct RenameColumn {
    let column: String
    let to: String
}

struct DropColumn {
    let column: String
}

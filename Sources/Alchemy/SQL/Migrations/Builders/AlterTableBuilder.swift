import Foundation

public final class AlterTableBuilder: CreateTableBuilder {
    /// Columns
    var dropColumns: [DropColumn] = []
    var renameColumns: [RenameColumn] = []
    
    /// Indexes
    var dropIndexes: [String] = []
}

extension AlterTableBuilder {
    public func drop(column: String) {
        self.dropColumns.append(DropColumn(column: column))
    }
    
    public func rename(column: String, to: String) {
        self.renameColumns.append(RenameColumn(column: column, to: to))
    }
    
    public func drop(index: String) {
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

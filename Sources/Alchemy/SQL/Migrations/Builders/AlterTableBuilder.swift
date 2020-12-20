import Foundation

/// A builder for altering the columns of an existing table.
public final class AlterTableBuilder: CreateTableBuilder {
    /// Any columns that should be dropped.
    var dropColumns: [String] = []
    
    /// Any columns that should be renamed.
    var renameColumns: [(from: String, to: String)] = []
    
    /// Any indexes that should be dropped.
    var dropIndexes: [String] = []
}

extension AlterTableBuilder {
    /// Drop a column.
    ///
    /// - Parameter column: the name of the column to drop.
    public func drop(column: String) {
        self.dropColumns.append(column)
    }
    
    /// Rename a column.
    ///
    /// - Parameters:
    ///   - column: the name of the column to rename.
    ///   - to: the new name for the column.
    public func rename(column: String, to: String) {
        self.renameColumns.append((from: column, to: to))
    }
    
    /// Drop an index.
    ///
    /// - Parameter index: the name of the index to drop.
    public func drop(index: String) {
        self.dropIndexes.append(index)
    }
}

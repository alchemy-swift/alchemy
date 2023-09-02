/// A builder for altering the columns of an existing table.
public final class AlterTableBuilder: CreateTableBuilder {
    /// Any columns that should be dropped.
    var dropColumns: [String] = []
    
    /// Any columns that should be renamed.
    var renameColumns: [(from: String, to: String)] = []
    
    /// Any indexes that should be dropped.
    var dropIndexes: [String] = []

    /// Any columns to update.
    var alterColumns: [CreateColumn] {
        super.createColumns.filter(\.isUpdate)
    }

    /// Any columns to create.
    override var createColumns: [CreateColumn] {
        super.createColumns.filter { !$0.isUpdate }
    }

    /// Drop a column.
    ///
    /// - Parameter column: The name of the column to drop.
    public func drop(column: String) {
        dropColumns.append(column)
    }

    /// Drop the `created_at` and `updated_at` columns.
    public func dropTimestamps() {
        dropColumns.append(contentsOf: ["created_at", "updated_at"])
    }

    /// Drop the `deleted_at` column.
    public func dropSoftDeletes() {
        dropColumns.append(contentsOf: ["deleted_at"])
    }

    /// Rename a column.
    ///
    /// - Parameters:
    ///   - column: The name of the column to rename.
    ///   - to: The new name for the column.
    public func rename(column: String, to: String) {
        renameColumns.append((from: column, to: to))
    }

    /// Drop an index.
    ///
    /// - Parameter index: The name of the index to drop.
    public func drop(index: String) {
        dropIndexes.append(index)
    }
}

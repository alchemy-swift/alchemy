/// A type for keeping track of data associated with creating an
/// index.
public struct CreateIndex {
    /// The columns that make up this index.
    let columns: [String]
    
    /// Whether this index is unique or not.
    let isUnique: Bool
    
    /// Generate the name of this index given the table it will be created on.
    /// The name will be suffixed with "key" if it's a unique index or "idx"
    /// if not.
    ///
    /// - Parameter table: The table this index will be created on.
    /// - Returns: The name of this index.
    func name(table: String) -> String {
        let suffix = isUnique ? "key" : "idx"
        return ([table] + columns + [suffix]).joined(separator: "_")
    }
}

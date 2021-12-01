public protocol StorageProvider {
    /// The root directory for storing and fetching files.
    var root: String { get }
    
    /// Create a file in this storage.
    /// - Parameters:
    ///  - filename: The name of the file, including extension, to create.
    ///  - directory: The directory to put the file in. If nil, goes in root.
    ///  - contents: the binary contents of the file.
    /// - Returns: The newly created file.
    @discardableResult
    func create(_ filepath: String, contents: ByteBuffer) async throws -> File
    
    /// Returns whether a file with the given path exists.
    func exists(_ filepath: String) async throws -> Bool
    
    /// Gets a file with the given path.
    func get(_ filepath: String) async throws -> File
    
    /// Delete a file at the given path.
    func delete(_ filepath: String) async throws
}
